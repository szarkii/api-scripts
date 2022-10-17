#!/usr/bin/python3

import getopt
from mimetypes import init
import os
import sys
import cv2
from picamera.array import PiRGBArray
from picamera import PiCamera
import numpy as np
from PIL import Image as im
import time
from time import sleep
from datetime import datetime
import psutil
import datetime as dt
import signal

version = "0.2.1"

# TODO Extract to a library


class ImageService:
    def __init__(self):
        self.kernel = np.ones((20, 20), np.uint8)

    def convert_to_gray(self, image):
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        gray = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, self.kernel)
        gray = cv2.medianBlur(gray, 5)

        return gray

    def draw_contours(self, image, coordinates):
        x, y, w, h = coordinates
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 3)

        x2 = x + int(w / 2)
        y2 = y + int(h / 2)
        cv2.circle(image, (x2, y2), 4, (0, 255, 0), -1)

        text = "x: " + str(x2) + ", y: " + str(y2)
        cv2.putText(image, text, (x2 - 10, y2 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    def save_to_file(self, path, image):
        data = im.fromarray(image)
        data.save(path)

# TODO Extract to a library


class ImagesDifference:
    def __init__(self, first_image, second_image, similarity_threshold):
        self.first_image = first_image
        self.second_image = second_image
        self.similarity_threshold = similarity_threshold

    def calculate_difference(self):
        absolute_difference = cv2.absdiff(self.first_image, self.second_image)
        _, absolute_difference = cv2.threshold(absolute_difference, int(
            self.similarity_threshold), 255, cv2.THRESH_BINARY)
        contours, hierarchy = cv2.findContours(
            absolute_difference, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)[-2:]
        areas = [cv2.contourArea(c) for c in contours]

        if len(areas) < 1:
            self.images_different = False
        else:
            self.images_different = True
            x, y, w, h = cv2.boundingRect(contours[np.argmax(areas)])
            self.coordinates = (x, y, w, h)

    def are_different(self):
        return self.images_different

    def get_difference_coordinates(self):
        return self.coordinates

    def get_similarity_percentage(self):
        if self.images_different is False:
            return 0

        image_height, image_width = (self.second_image.shape)
        image_area = image_width * image_height
        _, _, difference_width, difference_height = (
            self.get_difference_coordinates())
        difference_area = difference_width + difference_height

        return difference_area / image_area * 100


class Camera:
    def __init__(self, log, width, height, framerate, zoom):
        self.log = log
        self.buffer_width = 608
        self.buffer_height = 400
        self.width = width
        self.height = height
        self.framerate = framerate
        self.zoom = zoom

    def init(self):
        self.camera = PiCamera()
        self.camera.resolution = (self.width, self.height)
        self.camera.framerate = self.framerate
        self.camera.zoom = self.zoom
        self.raw_capture = PiRGBArray(self.camera, size=(
            self.buffer_width, self.buffer_height))
        signal.signal(signal.SIGINT, self.close)
        signal.signal(signal.SIGTERM, self.close)
        sleep(2)

    def take_photo(self, path):
        self.camera.capture(path)

    def capture_continuous(self):
        return self.camera.capture_continuous(self.raw_capture, format="bgr", use_video_port=True, resize=(self.buffer_width, self.buffer_height))

    def clear_frame(self):
        self.raw_capture.truncate(0)

    def record(self, path, seconds):
        self.camera.start_recording(path)
        self.camera.wait_recording(seconds)
        self.camera.stop_recording()

    def close(self, *args):
        self.log.info("Disabling camera.")
        self.camera.close()


class Log:
    def __init__(self, date_format_service, paths_service):
        self.date_format_service = date_format_service
        self.paths_service = paths_service

    def error(self, message):
        self.log_with_level("ERROR", message)

    def info(self, message):
        self.log_with_level("INFO", message)

    def log_with_level(self, level, message):
        day = self.date_format_service.get_date_in_file_format()
        time = self.date_format_service.get_time_in_log_format()
        log_entry = "[" + level + "] [" + day + "_" + time + "] " + message

        file = open(self.paths_service.get_log_file_path(), "a")
        print(log_entry)
        file.write(log_entry + "\n")
        file.close()


class DateFormatService:
    def __init__(self):
        pass

    def get_date_in_file_format(self):
        return self.get_datetime_using_format("%Y-%m-%d")

    def get_datetime_with_milliseconds_in_file_format(self):
        return self.get_datetime_using_format("%Y-%m-%d_%H-%M-%S_%f")

    def get_datetime_in_file_format(self):
        return self.get_datetime_using_format("%Y-%m-%d_%H-%M-%S")

    def get_time_in_log_format(self):
        return self.get_datetime_using_format("%H:%M:%S")

    def get_datetime_using_format(self, format):
        return datetime.now().strftime(format)


class PathsService:
    def __init__(self, output_directory_root, date_format_service):
        self.output_directory_root = output_directory_root
        self.date_format_service = date_format_service

    def get_log_file_path(self):
        filename = self.date_format_service.get_date_in_file_format() + ".log"

        return os.path.join(self.output_directory_root, filename)

    def get_difference_photo_path(self):
        return self.get_path_for_current_day_directory("diff", "jpg")

    def get_video_path(self):
        return self.get_path_for_current_day_directory("out", "h264")

    def get_snapshots_directory(self):
        snapshots = self.get_directory_in_current_day_directory("snapshots")
        current_series = self.date_format_service.get_datetime_in_file_format()
        return self.create_directory_if_not_exist(os.path.join(snapshots, current_series))

    def get_snapshot_filename(self):
        return self.date_format_service.get_datetime_with_milliseconds_in_file_format() + ".jpg"

    def get_healthcheck_path(self):
        return self.get_path_for_current_day_directory("healthcheck", "jpg")

    def get_path_for_current_day_directory(self, subdirectory, extension):
        directory = self.get_directory_in_current_day_directory(subdirectory)
        return os.path.join(directory, self.date_format_service.get_datetime_with_milliseconds_in_file_format() + "." + extension)

    def get_directory_in_current_day_directory(self, directory):
        return self.create_directory_if_not_exist(os.path.join(self.get_current_day_directory(), directory))

    def get_current_day_directory(self):
        directory = os.path.join(
            self.output_directory_root, self.date_format_service.get_date_in_file_format())
        return self.create_directory_if_not_exist(directory)

    def create_directory_if_not_exist(self, path):
        if not os.path.exists(path):
            os.makedirs(path)
        return path


class TimeIntervalService:
    def is_time_within(self, start_minutes_from_midnight, end_minutes_from_midnight):
        now = dt.datetime.now()
        current_minutes_from_midnight = now.hour * 60 + now.minute

        return current_minutes_from_midnight >= start_minutes_from_midnight and current_minutes_from_midnight < end_minutes_from_midnight

    def get_minutes_from_midnight(self, formatted_hour_and_minute):
        hour_and_minute = formatted_hour_and_minute.split(":")
        return int(hour_and_minute[0]) * 60 + int(hour_and_minute[1])


class DetectionStrategyService:
    def __init__(self, strategies):
        self.strategies = strategies

    def get_strategy(self):
        for strategy in self.strategies:
            if strategy.should_be_applied() is True:
                return strategy

        return None


class ContinuousRecordStrategy:
    def __init__(self, time_interval_service, record_service, log, continuous_record_time_interval):
        self.time_interval_service = time_interval_service
        self.record_service = record_service
        self.log = log

        if continuous_record_time_interval is None:
            self.strategy_enabled = False
        else:
            self.strategy_enabled = True
            (start_record_time, end_record_time) = continuous_record_time_interval.split("-")
            self.start_record_minutes_from_midnight = self.time_interval_service.get_minutes_from_midnight(
                start_record_time)
            self.end_record_minutes_from_midnight = self.time_interval_service.get_minutes_from_midnight(
                end_record_time)

    def should_be_applied(self):
        return self.strategy_enabled and self.time_interval_service.is_time_within(self.start_record_minutes_from_midnight, self.end_record_minutes_from_midnight)

    def should_record(self, first_frame, second_frame):
        return True

    def record(self):
        log.info("Continuous recording is in effect.")
        record_service.record()


class NonRecordStrategy:
    def __init__(self, time_interval_service, log, pause_record_time_interval):
        self.time_interval_service = time_interval_service
        self.log = log
        self.next_log_time = int(time.time())
        self.log_inteval = 600

        if pause_record_time_interval is None:
            self.strategy_enabled = False
        else:
            self.strategy_enabled = True
            (pause_record_time, resume_record_time) = pause_record_time_interval.split("-")
            self.pause_record_minutes_from_midnight = self.time_interval_service.get_minutes_from_midnight(
                pause_record_time)
            self.resume_record_minutes_from_midnight = self.time_interval_service.get_minutes_from_midnight(
                resume_record_time)

    def should_be_applied(self):
        should_be_applied = self.strategy_enabled and self.time_interval_service.is_time_within(
            self.pause_record_minutes_from_midnight, self.resume_record_minutes_from_midnight)

        if should_be_applied and self.next_log_time <= int(time.time()):
            self.log.info("Non record strategy is in effect.")
            self.next_log_time = int(time.time()) + self.log_inteval

        return should_be_applied

    def should_record(self, first_frame, second_frame):
        return False

    def record(self):
        pass


class MovementDetectionStrategy:
    def __init__(self, record_service, image_service, paths_service, log, difference_threshold):
        self.record_service = record_service
        self.difference_threshold = difference_threshold
        self.image_service = image_service
        self.paths_service = paths_service
        self.log = log

    def should_be_applied(self):
        return True

    def should_record(self, first_image, second_image):
        self.image = second_image
        first_image_gray = self.image_service.convert_to_gray(first_image)
        second_image_gray = self.image_service.convert_to_gray(second_image)

        self.images_difference = ImagesDifference(
            first_image_gray, second_image_gray, self.difference_threshold)
        self.images_difference.calculate_difference()

        return self.images_difference.are_different()

    def record(self):
        self.image_service.draw_contours(
            self.image, self.images_difference.get_difference_coordinates())
        path = self.paths_service.get_difference_photo_path()
        self.image_service.save_to_file(path, self.image)
        self.log.info("Difference detected and saved under " + path)
        self.record_service.record()


class HealthcheckDetectionStrategy:
    def __init__(self, paths_service, camera, log, healthcheck_interval):
        self.paths_service = paths_service
        self.camera = camera
        self.log = log
        self.healthcheck_interval = healthcheck_interval
        self.next_check_time = int(time.time())

    def should_be_applied(self):
        return self.next_check_time <= int(time.time())

    def should_record(self, first_image, second_image):
        return True

    def record(self):
        path = self.paths_service.get_healthcheck_path()
        self.camera.take_photo(path)
        self.log.info("Healthcheck snapshot saved under " + path)
        self.next_check_time = int(time.time()) + self.healthcheck_interval


class RecordService:
    def __init__(self, paths_service, camera, record_interval, take_photos_strategy):
        self.paths_service = paths_service
        self.camera = camera
        self.record_interval = record_interval

        if take_photos_strategy:
            self.record_function = self.take_pictures
        else:
            self.record_function = self.record_video

    def record(self):
        self.record_function()

    def record_video(self):
        path = self.paths_service.get_video_path()
        self.camera.record(path, self.record_interval)

    def take_pictures(self):
        end_time = int(time.time()) + self.record_interval
        directory = self.paths_service.get_snapshots_directory()

        while int(time.time()) < end_time:
            path = os.path.join(
                directory, self.paths_service.get_snapshot_filename())
            self.camera.take_photo(path)


# Default values
width = 1920
height = 1088
framerate = 30
zoom = [0.0, 0.0, 1.0, 1.0]
output_directory_root = os.path.join(
    os.path.expanduser('~'), "szarkii-apps", "szarkii-detector")
difference_threshold = 80
continuous_record_time_interval = None
pause_record_time_interval = None
record_interval = 120
max_space = 400
take_photos_strategy = False
healthcheck_interval = 600

help = sys.argv[0] + " - starts recording on movement or at a specific time.\n"
help += "-w --width      video width, default: " + str(width) + "\n"
help += "-h --height     video height, default: " + str(height) + "\n"
help += "-f --framerate  video framerate, default: " + str(framerate) + "\n"
help += "-z --zoom       region of interest, indicating the proportion of the image\n"
help += "                format: 'x,y,w,h', e.g. 0.5,0.7,0.3,0.3\n"
help += "-o --output     root directory for all files\n"
help += "                default:" + output_directory_root + "\n"
help += "-d --difference difference threshold (0-255), smaller is more accurate\n"
help += "-c --continuous-record\n"
help += "                time when recording is forced (e.g. 12:00-12:59)\n"
help += "-p --pause-record\n"
help += "                time when recording and detection is disabled (e.g. 12:00-12:59)\n"
help += "-i --interval   video duration in seconds, default: " + \
    str(record_interval) + "\n"
help += "-s --max-space  max memory space in MB that can left, before stopping further\n"
help += "                recording, default: " + str(max_space) + " MB\n"
help += "-t --photos     takes phoTos on movement instead of video - better quality\n"
help += "-l --healthcheck\n"
help += "                heaLthcheck snapshot interval, default: " + \
    str(healthcheck_interval) + " s\n"

# TODO Extract to a library
if len(sys.argv) == 1 and ("-h" in sys.argv or "--help" in sys.argv):
    print(help)
    exit()

if "-v" in sys.argv or "--version" in sys.argv:
    print(version)
    exit()


try:
    opts, args = getopt.getopt(sys.argv[1:], "w:h:f:z:o:d:c:p:i:s:l:t", ["width=", "height=", "framerate=", "zoom=", "output=",
                               "difference=", "continuous-record=", "pause-record=", "interval=", "max-space=", "healthcheck=", "photos="])
except getopt.GetoptError:
    print(help)
    sys.exit(2)
for opt, arg in opts:
    if opt in ("-w", "--width"):
        width = int(arg)
    elif opt in ("-h", "--height"):
        height = int(arg)
    elif opt in ("-f", "--framerate"):
        framerate = arg
    elif opt in ("-z", "--zoom"):
        zoom = [float(i) for i in arg.split(",")]
    elif opt in ("-o", "--output"):
        output_directory_root = arg
    elif opt in ("-d", "--difference"):
        difference_threshold = arg
    elif opt in ("-c", "--continuous-record"):
        continuous_record_time_interval = arg
    elif opt in ("-p", "--pause-record"):
        pause_record_time_interval = arg
    elif opt in ("-i", "--interval"):
        record_interval = int(arg)
    elif opt in ("-s", "--max-space"):
        max_space = int(arg)
    elif opt in ("-t", "--photos"):
        take_photos_strategy = True
    elif opt in ("-l", "--healthcheck"):
        healthcheck_interval = int(arg)

if not os.path.exists(output_directory_root):
    os.makedirs(output_directory_root)


image_service = ImageService()
date_format_service = DateFormatService()
paths_service = PathsService(output_directory_root, date_format_service)
log = Log(date_format_service, paths_service)
camera = Camera(log, width, height, framerate, zoom)
time_interval_service = TimeIntervalService()
record_service = RecordService(
    paths_service, camera, record_interval, take_photos_strategy)
detection_strategy_service = DetectionStrategyService((
    HealthcheckDetectionStrategy(
        paths_service, camera, log, healthcheck_interval),
    ContinuousRecordStrategy(
        time_interval_service, record_service, log, continuous_record_time_interval),
    NonRecordStrategy(time_interval_service, log, pause_record_time_interval),
    MovementDetectionStrategy(
        record_service, image_service, paths_service, log, difference_threshold)
))

log.info("Started with configuration:")
log.info("width: " + str(width))
log.info("height: " + str(height))
log.info("framerate: " + str(framerate))
log.info("zoom: " + str(zoom))
log.info("output directory root: " + str(output_directory_root))
log.info("difference threshold: " + str(difference_threshold))
log.info("continuous time interval: " + str(continuous_record_time_interval))
log.info("pause record time interval: " + str(pause_record_time_interval))
log.info("record time interval (s): " + str(record_interval))
log.info("max space (MB): " + str(max_space))
log.info("on movement strategy: " +
         ("take photos" if take_photos_strategy else "record"))
log.info("healthcheck interval (s): " + str(healthcheck_interval))

try:
    camera.init()
    log.info("Camera enabled.")
    previous_image = None

    for frame in camera.capture_continuous():
        image = np.array(frame.array)

        if previous_image is None:
            previous_image = image
            camera.clear_frame()
            continue

        strategy = detection_strategy_service.get_strategy()
        if strategy.should_record(previous_image, frame.array):
            strategy.record()
            previous_image = None
        else:
            previous_image = image

        if psutil.disk_usage(".").free < (max_space * 1000000):
            log.error("Not enough space.")
            exit(2)

        camera.clear_frame()
except KeyboardInterrupt:
    log.error("Keyboard interrupt.")
finally:
    camera.close()
    exit()

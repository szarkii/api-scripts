#!/usr/bin/python3

import getopt
import os
import sys
import cv2
import numpy as np
from PIL import Image as im

version="1.1.3"

class ImageService:
    def __init__(self):
        self.kernel = np.ones((20, 20), np.uint8)

    def convert_to_gray(self, image):
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        gray = cv2.morphologyEx(gray,cv2.MORPH_CLOSE, self.kernel)
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

class ImagesDifference:
    def __init__(self, first_image, second_image, similarity_threshold):
        self.first_image = first_image
        self.second_image = second_image
        self.similarity_threshold = similarity_threshold

    def calculate_difference(self):
        absolute_difference = cv2.absdiff(self.first_image, self.second_image)
        _, absolute_difference = cv2.threshold(absolute_difference, int(self.similarity_threshold), 255, cv2.THRESH_BINARY)
        contours, hierarchy = cv2.findContours(absolute_difference, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)[-2:]
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
        image_area =  image_width * image_height
        _, _, difference_width, difference_height = (self.get_difference_coordinates())
        difference_area = difference_width + difference_height
        
        return difference_area / image_area * 100
        

help = sys.argv[0] + " [-h | --help] [-s similarity] [-p] [-o output] first_image second_image"
help += "\nReturns an information if the images are different (True/False)"
help += "\n   -s similarity index (number)"
help += "\n   -p print similarity percentage instead of True/False"
help += "\n   -o save file with a difference in different directory/name"

similarity_threshold = 20
output_path = None
number_of_required_arguments = 2
print_similarity_percentage = False

if "-h" in sys.argv or "--help" in sys.argv:
    print(help)
    exit()

if "-v" in sys.argv or "--version" in sys.argv:
    print(version)
    exit()

if "-p" in sys.argv:
    print_similarity_percentage = True
    sys.argv.remove("-p")

try:
    opts, args = getopt.getopt(sys.argv[1:], "s:o:")
    
except getopt.GetoptError:
    print("Error in the command.")
    print(help)
    sys.exit(2)
for opt, arg in opts:
    if opt == "-s":
        similarity_threshold = arg
        number_of_required_arguments += 2
    elif opt == "-o":
        output_path = arg
        number_of_required_arguments += 2

if len(sys.argv) <= number_of_required_arguments:
    print("Not enough arguments.")
    print(help)
    exit()

first_image_path = sys.argv[len(sys.argv) - 2]
second_image_path = sys.argv[len(sys.argv) - 1]

image_service = ImageService();
first_image = cv2.cvtColor(cv2.imread(first_image_path), cv2.COLOR_BGR2RGB)
second_image = cv2.cvtColor(cv2.imread(second_image_path), cv2.COLOR_BGR2RGB)
first_image_gray = image_service.convert_to_gray(first_image)
second_image_gray = image_service.convert_to_gray(second_image)

images_difference_service = ImagesDifference(first_image_gray, second_image_gray, similarity_threshold);
images_difference_service.calculate_difference()

if print_similarity_percentage is True:
    print("%.10f" % images_difference_service.get_similarity_percentage())
else:
    print(images_difference_service.are_different())

if images_difference_service.are_different() is True:
    image_service.draw_contours(second_image, images_difference_service.get_difference_coordinates())
    
    filename_without_extension, file_extension = os.path.splitext(second_image_path)
    
    if output_path is None:
        output_path = second_image_path.replace(filename_without_extension, filename_without_extension + "_difference")
    
    image_service.save_to_file(output_path, second_image)

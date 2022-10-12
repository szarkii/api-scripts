# Mock PiCamera for tests
import shutil
import cv2
from PIL import Image
import numpy

class Frame:
    def __init__(self, path):
        self.array = cv2.imread(path)

class PiCamera:
    def __init__(self):
        pass
        
    def capture(self, path):
        shutil.copyfile("sample1.jpg", path)
    
    def capture_continuous(self, raw_capture, format, use_video_port, resize):
        return (Frame("sample1.jpg"), Frame("sample1.jpg"), Frame("sample2.jpg"), Frame("sample1.jpg"), Frame("sample1.jpg"))
    
    def start_recording(self, path):
        pass
    
    def wait_recording(self, seconds):
        pass
    
    def stop_recording(self):
        pass
    
    def close(self):
        pass
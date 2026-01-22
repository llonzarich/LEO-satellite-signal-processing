#--------------------------------------------------------------------------------------------------------------------------
# purpose: this script converts a collection of annotated spectrograms in .xml --> a single .csv file.
# output: - annotated-spectrograms.csv: a .csv file with all the info for each annotated spectrogram that we'll use for training. 
# note: - originally, I was creating two .csv files -- training_data.csv (with all info for each annotated spectrogram that we'd be using for training), 
#         and validation_data.csv (with all info for each annotated spectrogram that we'd be using for validation)
#       - I will do train-test-split on the 1 csv file that I create here.
#       - 1 bounding box annotation file per image.
#--------------------------------------------------------------------------------------------------------------------------


import os
import glob
import pandas as pd
import xml.etree.ElementTree as ET


def xml_to_csv(path):
    xml_list = [] # create a list that will be populated with all the information in a spectrogram's .xml file. 
    for xml_file in glob.glob(path + '/*.xml'): # for each .xml file in the path...
        tree = ET.parse(xml_file) # parse the .xml file.
        root = tree.getroot()
        if root.find('object'):
            for member in root.findall('object'):
                bbx = member.find('bndbox')
                xmin = round(float(bbx.find('xmin').text))
                ymin = round(float(bbx.find('ymin').text))
                xmax = round(float(bbx.find('xmax').text))
                ymax = round(float(bbx.find('ymax').text))
                label = member.find('name').text
                value = (root.find('filename').text, int(root.find('size')[0].text), int(root.find('size')[1].text), label, xmin, ymin, xmax, ymax) # "grabbing" all the info from the .xml file as a long string.
                print(value) # show the string with all this information.
                xml_list.append(value) # append this string to the xml_list.
    
    column_name = ['filename', 'width', 'height', 'class_label', 'xmin', 'ymin', 'xmax', 'ymax'] # give the columns in the .csv file a name. note:
    xml_df = pd.DataFrame(xml_list, columns=column_name) # convert list of values into a structured pandas dataframe
    return xml_df # return the xml_dl list with each row being a separate xml spectrogram annotation. 


def main():
    image_path = os.path.join(os.getcwd(), 'bbox-data', 'annotated-spectrograms') # path to my .xml files: cwd/bbox-data/annotated-spectrograms.
    xml_df = xml_to_csv(image_path) # call the function 'xml_to_csv() to read all .xml files in the folder (specified by 'image_path' variable ==> a pandas DataFrame table, where each row is an .xml's file bounding box annotations.
    xml_df.to_csv('bbox-data/spectrogram-annotations.csv', index=None) # writes the xml_df dataframe (just created) to a .csv file (that we can open with Excel).
    print('Successfully converted all .xml annotations to csv.')

    
main() # run main() function.
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import datetime
import re

import warnings
from pandas.core.common import SettingWithCopyWarning
warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore", category=SettingWithCopyWarning)

def read_dataset(file_data1, file_data2, file_data3):
    data1 = file_data1
    data2 = file_data2
    data3 = file_data3
    data = data1.append([data2, data3])
    data.columns = ['Employee_ID', 'Name', 'Gender', 'Education_Level', 'Job_Category', 'Age', 'Score', 'Phone_Number', 
                        'Domicile_Province', 'First_Day_Employement']
    return data

def replace_mapping(data,column, dict_value):
    data[column] = data[column].replace(dict_value)
    return data[column]

def employee_score(data, column):
    data[column].fillna(0, inplace=True)
    data[column] = data[column].astype(str).str.replace(' -   ','0').astype(float).round(2)
    return data[column]

def first_day(data, column):
    data[column] = pd.to_datetime(data[column]).dt.strftime('%d/%m/%Y')
    return data[column]

def employee_name(data, column):
    data[column] = data[column].str.replace('@','')
    data[column] = data[column].str.replace('-','')
    data[column] = data[column].str.replace(',,','')
    data[column] = data[column].str.replace('.','')
    return data[column]

def employee_phone(data, column):
    fix_phone = []
    for phon_num in data[column]:
        if str(phon_num).startswith('62'):
            phon_num = str(phon_num).replace('62','0')
        elif str(phon_num).startswith('8'):
            phon_num = '0'+ str(phon_num)
            fix_phone.append(phon_num)

    data[column] = pd.Series(fix_phone)
    return data[column]

def age_to_dob(data, column):
    # Memisahkan umur menjadi tahun, bulan, dan hari
    data[column] = data[column].str.replace('years','').str.replace('month','').str.replace('days','').str.strip()
    temp_age =data[column].str.split(',', n=2, expand=True)

    # Mengonversi kolom ke dalam tipe data numerik
    temp_age = temp_age.apply(pd.to_numeric)
    temp_age.columns = ['years', 'months', 'days']

    # Menghitung tanggal kelahiran dalam satuan hari
    birth_days = temp_age['years'] * 365 + temp_age['months'] * 30 + temp_age['days']

    # Tanggal awal yang akan digunakan sebagai referensi
    start_date = pd.to_datetime('2020-01-01')

    # Menghitung tanggal kelahiran
    birth_date = start_date - pd.to_timedelta(birth_days, unit='D')

    data['Birth_Date'] = birth_date.dt.strftime('%d/%m/%Y')
    return data['Birth_Date']

def extract_age(data, column):
    # Memisahkan umur menjadi tahun, bulan, dan hari
    data[column] = data[column].str.replace('years','').str.replace('month','').str.replace('days','').str.strip()
    temp_age =data[column].str.split(',', n=2, expand=True)

    # Mengonversi kolom ke dalam tipe data numerik
    temp_age = temp_age.apply(pd.to_numeric)
    data[column] = temp_age[0]
    return data[column]

# menambahkan kategori kelompok umur
def age_group(age):
    age = int(age)
    age_group = ''
    # umur 20 - 35
    if age >= 20  and age <= 35:
        age_group = '20 - 35'
    # umur 35 - 45
    elif age >= 36  and age <= 45:
        age_group = '36 - 45'
    # umur 46 keatas
    elif age >= 46:
        age_group = '46 to Above'
    return age_group

def main():
    df_employee = read_dataset("dataset 2022.xlsx", sheet1='dataset1', sheet2='dataset2', sheet3='dataset3')

    df_employee['Gender'] = replace_mapping(df_employee,'Gender', {'M':'Pria', 'Male':'Pria', 'Lakilaki':'Pria', 'Laki-laki':'Pria', 'Man':'Pria', 
                                                        'F':'Wanita', 'Female':'Wanita', 'Perempuan':'Wanita'})
    df_employee['Education_Level'] = replace_mapping(df_employee, 'Education_Level',{'S1':'Sarjana', 'S2':'Pasca-Sarjana', 
                    'D1':'Diploma', 'D4':'Diploma', 'D3':'Diploma','SLTA':'Pra-Sarjana', 'SMA':'Pra-Sarjana'})
    df_employee['Job_Category'] = replace_mapping(df_employee, 'Job_Category',{'Senior Staff Band 2':'Senior Staff', 'Senior Staff Band 3':'Senior Staff', 
                                            'Functional Expert Band 3':'Senior Staff', 'Senior Staff Band 5':'Senior Staff', 
                                            'Functional Expert Band 2':'Functional Expert', 'Trainee':'Staff', 
                                            'Senior Vice President':'Vice President'})
    df_employee['Domicile_Province'] = replace_mapping(df_employee, 'Domicile_Province', {'Jakarta':'DKI Jakarta', 'JKT':'DKI Jakarta', 
                                                    'Jakarta Selatan':'DKI Jakarta','South Jakarta':'DKI Jakarta', 'East Jakarta':'DKI Jakarta', 
                                                    'West Java':'Jawa Barat', 'Jabar':'Jawa Barat', 'Bandung':'Jawa Barat', 
                                                    'Purwakarta':'Jawa Barat', 'Depok':'Jawa Barat', 'Bogor':'Jawa Barat', 
                                                    'Bekasi':'Jawa Barat', 'Kalideres':'Jawa Barat', 'Sukabumi':'Jawa Barat', 
                                                    'Purwokerto':'Jawa Tengah', 'Yogyakarta':'DI Yogyakarta', 'DIY':'DI Yogyakarta', 
                                                    'Tangerang Selatan' :'Tangerang','Denpasar':'Bali'})
    df_employee['Score'] = employee_score(df_employee, 'Score')
    df_employee['First_Day_Employement'] = first_day(df_employee, 'First_Day_Employement')
    df_employee['Name'] = employee_name(df_employee, 'Name')

    df_employee['Phone_Number'] = employee_phone(df_employee, 'Phone_Number')
    df_employee['Birth_Date'] = age_to_dob(df_employee, 'Age')
    df_employee['Age'] = extract_age(df_employee,'Age')
    df_employee['Age_Group'] = df_employee['Age'].apply(age_group)

    df_employee = df_employee[['Employee_ID', 'Name', 'Gender', 'Education_Level', 'Job_Category',
        'Birth_Date', 'Age', 'Age_Group', 'Score', 'Phone_Number',
        'Domicile_Province', 'First_Day_Employement']]
    df_employee.to_csv('cleaned_employee.csv', index=False)

if __name__ == "__main__":
    main()
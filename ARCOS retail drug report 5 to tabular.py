## THIS SCRIPT WILL RETURN:
#   ARCOS Retail Drug Summary Report 5 Scraped from PDF to Tabular Format
#   ARCOS Retail Drug summary reports: https://www.deadiversion.usdoj.gov/arcos/retail_drug_summary/arcos-drug-summary-reports.html
###############################################################


import pandas as pd
import re
import PyPDF2
pd.set_option("display.max_rows",None, "display.max_columns", None)

files = ["Insert file names to scrape"]

ARCOS_Retail_Summary_Report_5_1997_2005 = pd.DataFrame(columns=['Drug_Name', 'Drug_Code', 'Buyers', 'Total_Grams', 'Avg_Grams', 'Business_Activity', 'State', 'Date_Range', 'Source_BRG'])

for f in range(0, len(files)):
    file_path = files[f]
    object = PyPDF2.PdfFileReader(r"{}".format(file_path))
    NumPages = object.getNumPages()
    page_list = []
    for i in range(0, NumPages):
        page_content = object.getPage(i).extractText()
        page_list.append({i: page_content})
    if NumPages > 100: #files extracted from main report
        for i in page_list:
            for page, value in i.items():
                # Pull Header Information
                bba_search = 'BUSINESS ACTIVITY:'
                bba_loc = value.find(bba_search)
                bba_value = value[bba_loc + len(bba_search):bba_loc + len(bba_search) + 40]
                state_search = 'STATE:'
                state_loc = value.find(state_search)
                state_value = value[state_loc+len(state_search):bba_loc]
                date_search = 'REPORTING PERIOD:'
                date_loc = value.find(date_search)
                date_value = value[date_loc + len(date_search):state_loc]
                # Pull Data from Table
                value = value.replace('----------------------------------------------------------------------------------------------','break')
                value = value.replace('---------------------------------------------------------------------------------------------','break')
                value = value.replace('--------------------------------------------------------------------------------------------','break')
                value = value.replace('-------------------------------------------------------------------------------------------','break')
                table_break_loc = value.find('break')
                data = value[table_break_loc + len('break'):]
                data_trim = re.split(r'\s{2,}', data.strip()) #split anywhere there is more than 2 spaces
                if data_trim[-1] == '-':
                    data_trim.pop(-1)
                new_row = []
                for b in range(0, len(data_trim), 5):
                    new_row.append(data_trim[b: b + 5])
                table = pd.DataFrame(columns=['Drug_Name', 'Drug_Code', 'Buyers', 'Total_Grams', 'Avg_Grams'])
                for c in new_row:
                    table.loc[len(table)] = c
                table['Business_Activity'] = bba_value.strip()
                table['State'] = state_value.strip()
                table['Date_Range'] = date_value.strip()
                table['Source_BRG'] = file_path
            ARCOS_Retail_Summary_Report_5_1997_2005 = ARCOS_Retail_Summary_Report_5_1997_2005.append(table)
    elif file_path.find('rep5_99') >= 0: #1999 files have 2 cover pages (find returns -1 if it isn't true)
        for i in page_list[2:]:
            for page, value in i.items():
                # Pull Header Information
                bba_search = 'BUSINESS ACTIVITY:'
                bba_loc = value.find(bba_search)
                bba_value = value[bba_loc + len(bba_search):bba_loc + len(bba_search) + 40]
                state_search = 'STATE:'
                state_loc = value.find(state_search)
                state_value = value[state_loc+len(state_search):bba_loc]
                date_search = 'REPORTING PERIOD:'
                date_loc = value.find(date_search)
                date_value = value[date_loc + len(date_search):state_loc]
                # Pull Data from Table
                value = value.replace('----------------------------------------------------------------------------------------------','break')
                value = value.replace('---------------------------------------------------------------------------------------------','break')
                value = value.replace('--------------------------------------------------------------------------------------------','break')
                value = value.replace('-------------------------------------------------------------------------------------------','break')
                table_break_loc = value.find('break')
                data = value[table_break_loc + len('break'):]
                data_trim = re.split(r'\s{2,}', data.strip())
                if data_trim[-1] == '-':
                    data_trim.pop(-1)
                new_row = []
                for b in range(0, len(data_trim), 5):
                    new_row.append(data_trim[b: b + 5])
                table = pd.DataFrame(columns=['Drug_Name', 'Drug_Code', 'Buyers', 'Total_Grams', 'Avg_Grams'])
                for c in new_row:
                    table.loc[len(table)] = c
                table['Business_Activity'] = bba_value.strip()
                table['State'] = state_value.strip()
                table['Date_Range'] = date_value.strip()
                table['Source_BRG'] = file_path
            ARCOS_Retail_Summary_Report_5_1997_2005 = ARCOS_Retail_Summary_Report_5_1997_2005.append(table)
    else:
        for i in page_list[1:]: #rest of the files only have 1 cover page
            for page, value in i.items():
                # Pull Header Information
                bba_search = 'BUSINESS ACTIVITY:'
                bba_loc = value.find(bba_search)
                bba_value = value[bba_loc + len(bba_search):bba_loc + len(bba_search) + 40]
                state_search = 'STATE:'
                state_loc = value.find(state_search)
                state_value = value[state_loc+len(state_search):bba_loc]
                date_search = 'REPORTING PERIOD:'
                date_loc = value.find(date_search)
                date_value = value[date_loc + len(date_search):state_loc]
                # Pull Data from Table
                value = value.replace('----------------------------------------------------------------------------------------------','break')
                value = value.replace('---------------------------------------------------------------------------------------------','break')
                value = value.replace('--------------------------------------------------------------------------------------------','break')
                value = value.replace('-------------------------------------------------------------------------------------------','break')
                table_break_loc = value.find('break')
                data = value[table_break_loc + len('break'):]
                data_trim = re.split(r'\s{2,}', data.strip())
                if data_trim[-1] == '-':
                    data_trim.pop(-1)
                new_row = []
                for b in range(0, len(data_trim), 5):
                    new_row.append(data_trim[b: b + 5])
                table = pd.DataFrame(columns=['Drug_Name', 'Drug_Code', 'Buyers', 'Total_Grams', 'Avg_Grams'])
                for c in new_row:
                    table.loc[len(table)] = c
                table['Business_Activity'] = bba_value.strip()
                table['State'] = state_value.strip()
                table['Date_Range'] = date_value.strip()
                table['Source_BRG'] = file_path
            ARCOS_Retail_Summary_Report_5_1997_2005 = ARCOS_Retail_Summary_Report_5_1997_2005.append(table)
        


print(ARCOS_Retail_Summary_Report_5_1997_2005)
ARCOS_Retail_Summary_Report_5_1997_2005.to_excel("Insert excel export file name")

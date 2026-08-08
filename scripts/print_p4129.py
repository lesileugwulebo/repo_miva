import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx")
print("P4129:")
print(repr(doc.paragraphs[4129].text.encode('ascii', errors='replace').decode('ascii')))

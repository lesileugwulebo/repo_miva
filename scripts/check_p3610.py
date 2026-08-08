import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Final_Thesis.docx")
para = doc.paragraphs[3610]

print("Final P3610 text:")
print(repr(para.text))

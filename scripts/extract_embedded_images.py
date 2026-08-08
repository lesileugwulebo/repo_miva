import os
import zipfile

doc_path = "../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Final_Thesis.docx"
output_dir = "extracted_images"
os.makedirs(output_dir, exist_ok=True)

print("Extracting media files from the docx container...")
with zipfile.ZipFile(doc_path, 'r') as archive:
    media_files = [f for f in archive.namelist() if f.startswith('word/media/')]
    print(f"Found {len(media_files)} media files in the document:")
    for media in media_files:
        name = os.path.basename(media)
        dest = os.path.join(output_dir, name)
        with open(dest, 'wb') as f_out:
            f_out.write(archive.read(media))
        print(f"  Saved {name} ({os.path.getsize(dest)} bytes)")

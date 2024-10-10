import logging
import os
import subprocess

import requests

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


def render_quarto():
    try:
        logging.info("Starting Quarto render process.")
        # Run the quarto render command
        result = subprocess.run(['quarto', 'render', 'index.qmd'], check=True, capture_output=True, text=True)
        logging.info("Quarto render completed successfully.")
        logging.debug(f"Quarto render output: {result.stdout}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error rendering Quarto document: {e.stderr}")
        raise


def update_quarto(files_to_upload: list[str]):
    logging.info("Starting Quarto update process.")
    multipart_form_data = {}
    for file_path in files_to_upload:
        file_name = os.path.basename(file_path)
        with open(file_path, 'rb') as file:
            # Read the file contents and store them in the dictionary
            file_contents = file.read()
            multipart_form_data[file_name] = (file_name, file_contents)
            logging.debug(f"Prepared file for upload: {file_name}")

    try:
        # Send the request with all files in the dictionary
        response = requests.put(
            f"https://{os.environ['ENV']}/quarto/update/{os.environ['QUARTO_ID']}",
            headers={"Authorization": f"Bearer {os.environ['NADA_TOKEN']}"},
            files=multipart_form_data
        )
        response.raise_for_status()
        logging.info("Quarto update completed successfully.")
    except requests.RequestException as e:
        logging.error(f"Error updating Quarto document: {e}")
        raise



if __name__ == '__main__':
    logging.info("Script started.")
    try:
        render_quarto()
        update_quarto(files_to_upload=["index.html"])
    except Exception as e:
        logging.error(f"Script failed: {e}")
    logging.info("Script finished.")

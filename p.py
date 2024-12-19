import os
import db

def rename_card_images():
    # Connect to the database
    with db.connect() as conn:
        with conn.cursor() as cur:
            # Fetch the card names and their current image filenames
            cur.execute('SELECT nom FROM carte')
            cards = cur.fetchall()

            # Define the path to the static/carte directory
            static_carte_path = os.path.join(os.getcwd(), 'static', 'cartes')
            n = 85
            for card in cards:
                n+=1
                
                # Define the current and new file paths
                current_file_path = os.path.join(static_carte_path, f"carte_{n}.png")
                new_file_path = os.path.join(static_carte_path, f"{card.nom}.jpg")

                # Rename the file
                if os.path.exists(current_file_path):
                    os.rename(current_file_path, new_file_path)
                    print(f"Renamed {current_file_path} to {new_file_path}")
                else:
                    print(f"File {current_file_path} does not exist")

if __name__ == "__main__":
    rename_card_images()
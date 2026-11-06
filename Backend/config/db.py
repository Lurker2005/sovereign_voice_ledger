import os
from pathlib import Path
import mysql.connector
from dotenv import load_dotenv

# Locate the Backend folder
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from Backend/.env
load_dotenv(BASE_DIR / ".env")


def get_db_connection():
    connection = mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        port=int(os.getenv("DB_PORT"))
    )

    return connection
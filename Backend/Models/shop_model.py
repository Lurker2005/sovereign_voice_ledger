
from Backend.config.db import get_db_connection


def create_shop(shop_name, owner_name, phone, email=None, address=None):

    connection = None
    cursor = None

    try:
        # Establish database connection
        connection = get_db_connection()

        # Create cursor
        cursor = connection.cursor()

        # SQL query to insert shop details
        query = """
            INSERT INTO shops
            (shop_name, owner_name, phone, email, address)
            VALUES (%s, %s, %s, %s, %s)
        """

        values = (shop_name, owner_name, phone, email, address)

        # Execute query
        cursor.execute(query, values)

        # Save changes
        connection.commit()

        # Get the newly generated shop ID
        shop_id = cursor.lastrowid

        return shop_id

    except Exception:
        # Undo changes if something goes wrong
        if connection:
            connection.rollback()

        raise

    finally:
        # Close database resources
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()

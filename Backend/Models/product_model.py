
from Backend.config.db import get_db_connection


def create_product(shop_id, product_name, unit, unit_price):

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        query = """
            INSERT INTO products
            (shop_id, product_name, unit, unit_price)
            VALUES (%s, %s, %s, %s)
        """

        values = (shop_id, product_name, unit, unit_price)

        cursor.execute(query, values)
        connection.commit()

        return cursor.lastrowid

    except Exception:
        if connection:
            connection.rollback()
        raise

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()


def get_products_by_shop(shop_id):

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT product_id, shop_id, product_name,
                   unit, unit_price, is_active
            FROM products
            WHERE shop_id = %s
            ORDER BY product_name
        """

        cursor.execute(query, (shop_id,))

        return cursor.fetchall()

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()


def update_product(shop_id, product_id, product_name, unit, unit_price):

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        query = """
            UPDATE products
            SET product_name = %s,
                unit = %s,
                unit_price = %s
            WHERE product_id = %s
              AND shop_id = %s
              AND is_active = TRUE
        """

        values = (
            product_name,
            unit,
            unit_price,
            product_id,
            shop_id
        )

        cursor.execute(query, values)
        connection.commit()

        return cursor.rowcount > 0

    except Exception:
        if connection:
            connection.rollback()
        raise

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()


def deactivate_product(shop_id, product_id):

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        query = """
            UPDATE products
            SET is_active = FALSE
            WHERE product_id = %s
              AND shop_id = %s
              AND is_active = TRUE
        """

        cursor.execute(query, (product_id, shop_id))
        connection.commit()

        return cursor.rowcount > 0

    except Exception:
        if connection:
            connection.rollback()
        raise

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()


from Backend.config.db import get_db_connection


def find_customers_by_name(shop_id, customer_name):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT customer_id, shop_id, customer_name, phone, address
            FROM customers
            WHERE shop_id = %s
              AND LOWER(TRIM(customer_name)) = LOWER(TRIM(%s))
            ORDER BY customer_id
        """

        cursor.execute(query, (shop_id, customer_name))
        return cursor.fetchall()

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


def find_customer_by_phone(shop_id, phone):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT customer_id, shop_id, customer_name, phone, address
            FROM customers
            WHERE shop_id = %s AND phone = %s
        """

        cursor.execute(query, (shop_id, phone))
        return cursor.fetchone()

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


def create_customer_and_account(shop_id, customer_name, phone=None, address=None):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        # Create the customer.
        customer_query = """
            INSERT INTO customers
            (shop_id, customer_name, phone, address)
            VALUES (%s, %s, %s, %s)
        """

        cursor.execute(
            customer_query,
            (shop_id, customer_name, phone, address)
        )

        customer_id = cursor.lastrowid

        # Automatically create the customer's ledger account.
        account_query = """
            INSERT INTO customer_accounts
            (shop_id, customer_id, current_balance)
            VALUES (%s, %s, 0.00)
        """

        cursor.execute(
            account_query,
            (shop_id, customer_id)
        )

        account_id = cursor.lastrowid

        # Both records must be saved together.
        connection.commit()

        return {
            "customer_id": customer_id,
            "account_id": account_id
        }

    except Exception:
        if connection:
            connection.rollback()
        raise

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


def get_customers_by_shop(shop_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT
                c.customer_id,
                c.customer_name,
                c.phone,
                c.address,
                ca.account_id,
                ca.current_balance
            FROM customers c
            INNER JOIN customer_accounts ca
                ON c.shop_id = ca.shop_id
                AND c.customer_id = ca.customer_id
            WHERE c.shop_id = %s
            ORDER BY c.customer_name
        """

        cursor.execute(query, (shop_id,))
        return cursor.fetchall()

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


def get_customer_balance(shop_id, customer_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT
                c.customer_id,
                c.customer_name,
                ca.account_id,
                ca.current_balance
            FROM customers c
            INNER JOIN customer_accounts ca
                ON c.shop_id = ca.shop_id
                AND c.customer_id = ca.customer_id
            WHERE c.shop_id = %s
              AND c.customer_id = %s
        """

        cursor.execute(query, (shop_id, customer_id))
        return cursor.fetchone()

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()

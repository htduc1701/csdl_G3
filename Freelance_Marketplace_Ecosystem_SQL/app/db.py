import os

import mysql.connector


def _connect(user, password):
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=user,
        password=password,
        database="mini_upwork",
    )

def get_connection():
    password = os.getenv("DB_PASSWORD")
    if password is None:
        raise RuntimeError("Set DB_PASSWORD to your local MySQL password before starting Mini Upwork.")
    return _connect(os.getenv("DB_USER", "root"), password)

def get_client_connection(client_id):
    conn = _connect(f"client_{client_id}", "Client1@123")

    cursor = conn.cursor()
    cursor.execute(
        "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"
    )
    cursor.close()

    return conn

def get_freelancer_connection(freelancer_id):
    conn = _connect(f"freelancer_{freelancer_id}", "Freelancer4@123")

    cursor = conn.cursor()
    cursor.execute(
        "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"
    )
    cursor.close()

    return conn

def get_payment_connection():
    conn = _connect("payment_service", "Payment@123")

    cursor = conn.cursor()
    cursor.execute(
        "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED"
    )
    cursor.close()

    return conn

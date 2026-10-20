import mysql.connector

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        port=3306,
        user="root",
        password="duc170107",
        database="mini_upwork"
    )

def get_client_connection(client_id):
    return mysql.connector.connect(
        host="localhost",
        port=3306,
        user=f"client_{client_id}",
        password="Client1@123",
        database="mini_upwork"
    )

def get_freelancer_connection(freelancer_id):
    return mysql.connector.connect(
        host="localhost",
        port=3306,
        user=f"freelancer_{freelancer_id}",
        password="Freelancer4@123",
        database="mini_upwork"
    )
from flask import Flask, render_template, request, redirect, url_for
from app.db import (
    get_connection,
    get_client_connection,
    get_freelancer_connection
)

app = Flask(
    __name__,
    template_folder="app/templates",
    static_folder="app/static"
)

@app.route("/")
def home():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT DATABASE();")
    db_name = cursor.fetchone()[0]

    cursor.close()
    conn.close()

    return render_template("index.html", db_name=db_name)

@app.route("/client")
def client_dashboard():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
    SELECT
        j.job_id,
        j.title,
        j.budget_min,
        j.budget_max,
        j.deadline,
        j.status,
        c.company_name,
        jc.category_name
    FROM jobs j
    JOIN clients c
        ON j.client_id = c.client_id
    JOIN job_categories jc
        ON j.category_id = jc.category_id
    ORDER BY j.job_id DESC
    LIMIT 100;
""")

    jobs = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("client.html", jobs=jobs)

@app.route("/client/post-job", methods=["GET", "POST"])
def post_job():
    if request.method == "POST":
        client_id = int(request.form["client_id"])
        category_id = int(request.form["category_id"])
        title = request.form["title"]
        description = request.form["description"]
        budget_min = request.form["budget_min"]
        budget_max = request.form["budget_max"]
        deadline = request.form["deadline"] or None

        conn = get_client_connection(client_id)
        cursor = conn.cursor()

        try:
            cursor.callproc(
                "sp_post_job",
                [
                    client_id,
                    category_id,
                    title,
                    description,
                    budget_min,
                    budget_max,
                    deadline
                ]
            )

            conn.commit()

        finally:
            cursor.close()
            conn.close()

        return redirect(url_for("client_dashboard"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT category_id, category_name
        FROM job_categories
        ORDER BY category_id
    """)

    categories = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "post_job.html",
        categories=categories
    )

@app.route("/freelancer")
def freelancer_dashboard():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            j.job_id,
            j.title,
            j.description,
            j.budget_min,
            j.budget_max,
            j.deadline,
            j.status,
            c.company_name,
            jc.category_name
        FROM jobs j
        JOIN clients c
            ON j.client_id = c.client_id
        JOIN job_categories jc
            ON j.category_id = jc.category_id
        WHERE j.status = 'OPEN'
        ORDER BY j.job_id DESC
        LIMIT 100;
    """)

    jobs = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("freelancer.html", jobs=jobs)

@app.route(
    "/freelancer/job/<int:job_id>/proposal",
    methods=["GET", "POST"]
)
def submit_proposal(job_id):

    if request.method == "POST":

        freelancer_id = int(request.form["freelancer_id"])
        proposed_amount = request.form["proposed_amount"]
        cover_letter = request.form["cover_letter"]
        estimated_days = int(request.form["estimated_days"])

        conn = get_freelancer_connection(freelancer_id)
        cursor = conn.cursor()

        try:
            cursor.callproc(
                "sp_submit_proposal",
                [
                    freelancer_id,
                    job_id,
                    proposed_amount,
                    cover_letter,
                    estimated_days
                ]
            )

            conn.commit()

        finally:
            cursor.close()
            conn.close()

        return redirect(url_for("freelancer_dashboard"))

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT job_id, title
        FROM jobs
        WHERE job_id = %s
    """, (job_id,))

    job = cursor.fetchone()

    cursor.close()
    conn.close()

    return render_template(
        "proposal.html",
        job=job
    )

@app.route("/client/job/<int:job_id>/proposals")
def view_proposals(job_id):

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            job_id,
            client_id,
            title
        FROM jobs
        WHERE job_id = %s
    """, (job_id,))

    job = cursor.fetchone()

    cursor.execute("""
        SELECT
            p.proposal_id,
            p.freelancer_id,
            u.full_name,
            p.proposed_amount,
            p.estimated_days,
            p.status
        FROM proposals p
        JOIN users u
            ON p.freelancer_id = u.user_id
        WHERE p.job_id = %s
        ORDER BY p.proposal_id DESC
    """, (job_id,))

    proposals = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "job_proposals.html",
        job=job,
        proposals=proposals
    )

@app.route(
    "/client/proposal/<int:proposal_id>/select",
    methods=["POST"]
)
def select_proposal(proposal_id):

    client_id = int(request.form["client_id"])

    conn = get_client_connection(client_id)
    cursor = conn.cursor()

    try:
        cursor.callproc(
            "sp_select_proposal",
            [
                client_id,
                proposal_id
            ]
        )

        conn.commit()

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("client_dashboard"))

@app.route("/freelancer/proposals")
def my_proposals():

    freelancer_id = 4

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            p.proposal_id,
            p.proposed_amount,
            p.estimated_days,
            p.status,
            j.title
        FROM proposals p
        JOIN jobs j
            ON p.job_id = j.job_id
        WHERE p.freelancer_id = %s
        ORDER BY p.proposal_id DESC
        LIMIT 100
    """, (freelancer_id,))

    proposals = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "my_proposals.html",
        proposals=proposals
    )

@app.route(
    "/freelancer/proposal/<int:proposal_id>/confirm",
    methods=["POST"]
)
def confirm_proposal(proposal_id):

    freelancer_id = int(request.form["freelancer_id"])

    conn = get_freelancer_connection(freelancer_id)
    cursor = conn.cursor()

    try:
        cursor.callproc(
            "sp_confirm_proposal",
            [
                freelancer_id,
                proposal_id
            ]
        )

        conn.commit()

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for("my_proposals"))

@app.route("/client/contracts")
def client_contracts():
    client_id = 1

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            c.contract_id,
            c.proposal_id,
            c.client_id,
            c.freelancer_id,
            u.full_name AS freelancer_name,
            j.title AS job_title,
            c.start_date,
            c.end_date,
            c.total_amount,
            c.status
        FROM contracts c
        JOIN proposals p
            ON c.proposal_id = p.proposal_id
        JOIN jobs j
            ON p.job_id = j.job_id
        JOIN users u
            ON c.freelancer_id = u.user_id
        WHERE c.client_id = %s
        ORDER BY c.contract_id DESC
        LIMIT 100
    """, (client_id,))

    contracts = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "contracts.html",
        contracts=contracts
    )

@app.route(
    "/client/contract/<int:contract_id>/milestones",
    methods=["GET", "POST"]
)
def contract_milestones(contract_id):

    client_id = 1

    if request.method == "POST":

        title = request.form["title"]
        amount = request.form["amount"]
        due_date = request.form["due_date"] or None

        conn = get_client_connection(client_id)
        cursor = conn.cursor()

        try:
            cursor.callproc(
                "sp_add_milestone",
                [
                    client_id,
                    contract_id,
                    title,
                    amount,
                    due_date
                ]
            )

            conn.commit()

        finally:
            cursor.close()
            conn.close()

        return redirect(
            url_for(
                "contract_milestones",
                contract_id=contract_id
            )
        )

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            contract_id,
            client_id,
            total_amount,
            start_date,
            end_date,
            status
        FROM contracts
        WHERE contract_id = %s
    """, (contract_id,))

    contract = cursor.fetchone()

    cursor.execute("""
        SELECT
            milestone_id,
            title,
            amount,
            due_date,
            status
        FROM milestones
        WHERE contract_id = %s
        ORDER BY milestone_id
    """, (contract_id,))

    milestones = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        "milestones.html",
        contract=contract,
        milestones=milestones
    )

if __name__ == "__main__":
    app.run(debug=True)
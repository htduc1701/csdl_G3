"""Regression tests for Freelancer selection. No real database writes."""
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import main


class FreelancerSelectionTests(unittest.TestCase):
    def setUp(self):
        main.app.config.update(TESTING=True)
        self.web = main.app.test_client()
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value
        self.cursor.fetchall.return_value = []
        read_patch = patch.object(main, "get_connection", return_value=self.conn)
        self.read = read_patch.start()
        self.addCleanup(read_patch.stop)
        write_patch = patch.object(main, "get_freelancer_connection")
        self.write = write_patch.start()
        self.addCleanup(write_patch.stop)
        self.write_cursor = self.write.return_value.cursor.return_value

    def test_each_id_filters_proposals_and_renders_correct_confirm_actor(self):
        for actor in (4, 5, 6, 7):
            with self.subTest(actor=actor):
                self.cursor.fetchall.return_value = [{
                    "proposal_id": 24815, "title": "test101",
                    "proposed_amount": 11, "estimated_days": 4,
                    "status": "CLIENT_ACCEPTED",
                }]
                response = self.web.get(f"/freelancer/proposals?freelancer_id={actor}")
                self.assertEqual(response.status_code, 200)
                self.assertEqual(self.cursor.execute.call_args.args[1], (actor,))
                body = response.get_data(as_text=True)
                self.assertIn("Confirm Proposal", body)
                self.assertRegex(body, rf'name="freelancer_id"\s+value="{actor}"')
                self.assertIn(f'/freelancer/milestones?freelancer_id={actor}', body)
                self.assertNotIn('<select', body)

    def test_only_client_accepted_proposals_can_show_confirm(self):
        for status in ("PENDING", "CONFIRMED"):
            self.cursor.fetchall.return_value = [{
                "proposal_id": 24814, "title": "test101",
                "proposed_amount": 90, "estimated_days": 10, "status": status,
            }]
            body = self.web.get("/freelancer/proposals").get_data(as_text=True)
            self.assertNotIn("Confirm Proposal", body)

    def test_selection_is_remembered_and_can_switch_back(self):
        for actor in (5, 4):
            self.web.get(f"/freelancer/proposals?freelancer_id={actor}")
            self.web.get("/freelancer/milestones")
            self.assertEqual(self.cursor.execute.call_args.args[1], (actor,))

    def test_submit_remembers_actor_for_my_proposals(self):
        response = self.web.post("/freelancer/job/23011/proposal", data={
            "freelancer_id": "5", "proposed_amount": "11",
            "cover_letter": "Test", "estimated_days": "4",
        })
        self.assertEqual(response.status_code, 302)
        self.write.assert_called_once_with(5)
        self.write_cursor.callproc.assert_called_once_with(
            "sp_submit_proposal", [5, 23011, "11", "Test", 4])
        self.web.get("/freelancer/proposals")
        self.assertEqual(self.cursor.execute.call_args.args[1], (5,))

    def test_confirm_5_uses_5_even_if_another_tab_switched_to_4(self):
        with self.web.session_transaction() as saved:
            saved["freelancer_id"] = 4
        response = self.web.post("/freelancer/proposal/24815/confirm",
                                 data={"freelancer_id": "5"})
        self.write.assert_called_once_with(5)
        self.write_cursor.callproc.assert_called_once_with(
            "sp_confirm_proposal", [5, 24815])
        self.write.return_value.commit.assert_called_once()
        self.assertEqual(response.location, "/freelancer/proposals?freelancer_id=5")

    def test_both_milestone_buttons_submit_selected_actor(self):
        self.cursor.fetchall.return_value = [{
            "milestone_id": number, "job_title": "test101", "title": "Work",
            "amount": 1, "due_date": None, "status": status,
        } for number, status in enumerate(("PENDING", "IN_PROGRESS"), 1)]
        response = self.web.get("/freelancer/milestones?freelancer_id=5")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.cursor.execute.call_args.args[1], (5,))
        body = response.get_data(as_text=True)
        self.assertEqual(body.count('type="hidden" name="freelancer_id" value="5"'), 2)
        for status in ("IN_PROGRESS", "COMPLETED"):
            self.write.reset_mock()
            response = self.web.post("/freelancer/milestone/9/advance", data={
                "freelancer_id": "5", "status": status,
            })
            self.write.assert_called_once_with(5)
            self.write_cursor.callproc.assert_called_once_with(
                "sp_advance_milestone", [5, 9, status])
            self.assertEqual(response.location, "/freelancer/milestones?freelancer_id=5")

    def test_invalid_ids_do_not_reach_database(self):
        for actor in ("", "abc", "3", "8", "4.5"):
            response = self.web.get(f"/freelancer/proposals?freelancer_id={actor}")
            self.assertEqual(response.status_code, 400)
            response = self.web.post("/freelancer/proposal/24815/confirm",
                                     data={"freelancer_id": actor})
            self.assertEqual(response.status_code, 400)
        self.read.assert_not_called()
        self.write.assert_not_called()

    def test_proposal_form_uses_remembered_id_and_stays_editable(self):
        self.cursor.fetchone.return_value = {"job_id": 23011, "title": "test101"}
        self.web.get("/freelancer/proposals?freelancer_id=5")
        response = self.web.get("/freelancer/job/23011/proposal")
        self.assertEqual(response.status_code, 200)
        body = response.get_data(as_text=True)
        self.assertRegex(body, r'type="number"\s+name="freelancer_id"')
        self.assertIn('value="5"', body)
        self.assertNotIn('readonly', body)


if __name__ == "__main__":
    unittest.main()

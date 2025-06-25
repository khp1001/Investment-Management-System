# Investment Management System

A database-driven system to manage and analyze investor portfolios across stocks, bonds, and mutual funds. Built with PostgreSQL, Flask, and SQL, the system applies real-world financial logic and normalization principles (up to BCNF) to deliver accurate, queryable investment insights.

---

## 🔧 Tech Stack

- **PostgreSQL** – Fully normalized schema (BCNF), hosted on Render
- **SQL** – Complex analytical queries for investment insights
- **Flask** – RESTful API backend to expose query results as JSON
- **Python (psycopg2)** – Database integration with Flask API

---

## 📦 Features

- 📊 Portfolio Breakdown: View investor allocation across stocks, bonds, and mutual funds
- 📈 Smart Insights: See stocks outperforming 6-day averages, bond-heavy investors, etc.
- 🔗 RESTful API: Access data and analytics via clean GET endpoints
- 📚 Normalization: All tables analyzed and designed to comply with BCNF
- ✅ Constraints: Enforced domain checks and referential integrity

---

## 🗃️ Project Structure

Investment-Management-System/
├── README.md
├── database/
│ ├── schema.sql
│ ├── normalization_report.pdf
│ ├── er_diagram.png
│ └── relational_diagram.png
├── queries/
│ ├── main_queries.sql
│ └── analytics_queries.sql
├── api/
│ ├── app.py
│ └── requirements.txt
├── sample_outputs/
│ └── example_output.json
└── deployment/
└── render_postgres_setup.txt

---

## 🚀 How to Run the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Investment-Management-System.git
   cd Investment-Management-System

2. Create and activate a virtual environment (optional but recommended):
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
3. Install dependencies:
   pip install -r api/requirements.txt
  
4. Start the Flask API server:
   python api/app.py

5. Test API endpoints in your browser:
   http://127.0.0.1:5000/investor_portfolio
   http://127.0.0.1:5000/stock_above_avg

---

## Future Improvements

- Add a frontend dashboard using React or Streamlit
- Implement authentication for advisors/investors
- Add transaction input endpoints (POST)
- Visualize data using Chart.js or Recharts

---

## License

This project is open-source under the MIT License.

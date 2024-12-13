# IPStudio/StudioWebApp Project

---

## Technologies Used

### Frontend:
- **React** (with Next.js)
- **Bootstrap** for styling
- **React Select** for dropdowns
- **SweetAlert** for confirmation dialogs

### Backend:
- **Lucee** server (ColdFusion engine)
- **Taffy** for RESTful API creation
- **MySQL** as the database

---

## Installation and Setup

### Prerequisites:
- Lucee server installed and configured.
- MySQL database set up with required schemas.

### Steps to Run:
1. **Clone the repository:**
   ```bash
   git clone https://github.com/interactivepulse/studio.interactivepulsedigital.com.git
   ```
2. **Backend Setup:**
   - Place the ColdFusion files in your Lucee web root directory.
   - Db dump is is provided in the the database directory on root.
   - Configure `Application.cfc` with your database credentials.

3. **Frontend Setup:**
   - Navigate to the React project directory.
   - Install dependencies:
     ```bash
     npm install
     ```
   - Run the development server:
     ```bash
     npm run dev
     ```

4. **Environment Variables:**
   - Frontend: Create a `.env.local` file for React and specify API URLs. An `env.example` file is provided in the root directory for reference."

---

## Project Structure

### Backend:
- `Application.cfc`: Main application configuration.
- `api/`: Contains Taffy APIs.
- `services/`: Scheduled tasks for Asana synchronization.

### Frontend:
- `pages/`: Next.js pages.
- `components/`: Reusable React components.
- `hooks/`: Custom React hooks for data fetching.
- `styles/`: Application styles.

---

## Development Notes
- **Lucee Specifics:**
  - Ensure the Lucee server is correctly configured for Taffy.
  - Use the admin panel to confirm datasource connectivity.




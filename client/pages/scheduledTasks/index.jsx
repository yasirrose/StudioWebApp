// pages/calendar/CalendarPage.jsx
import React, { useState, useEffect } from 'react';
import { Scheduler } from "@aldabil/react-scheduler";
import Header from "../../components/common/Header";
import Footer from "../../components/common/Footer";
import Sidebar from "../../components/common/Sidebar";
import HeaderScheduleTask from "../../components/common/HeaderScheduleTask";
import AddEventModal from "../../components/Shared/AddEventModal";
import { FaChevronLeft, FaChevronRight, FaFileExport, FaPlus } from 'react-icons/fa';
import { useEvents } from "./events";
import { useTheme } from '../../context/ThemeContext';
import FullCalendar from "@fullcalendar/react";
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from "@fullcalendar/daygrid";
import { useAuth } from "../../context/authContext";

export default function CalendarPage() {
    const [showAddEventModal, setShowAddEventModal] = useState(false);
    const { isAuthenticated } = useAuth();
    const { events, loading, error } = useEvents();
    const [collapsed, setCollapsed] = useState(false);
    console.log("---loading  tasks---", loading);

    const handleAddEventModalToggle = () => {
        setShowAddEventModal(!showAddEventModal);
    };

    const handleEventSubmit = (eventData) => {
        console.log("Event Data:", eventData);
        // Further actions like calling API to save the event
    };

    useEffect(() => {
        console.log("client id = ", localStorage.getItem('clientId'));
        
        // if (error) {
        //     console.error(error);
        // }
    }, []);

    const { theme, isDarkMode } = useTheme();

    return (
        <div className={`main-screen ${isAuthenticated ? 'no-sidebar-header' : ''} ${ theme === "system" ? "systemMode" : isDarkMode ? "darkMode" : "lightMode" }`}>
            {!isAuthenticated && <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />}
            <div className={`main-content ${collapsed ? 'collapsed' : ''}`}>
                {!isAuthenticated && <Header />}
                {isAuthenticated && <HeaderScheduleTask />}
                <div className="app-main flex-column flex-row-fluid" id="kt_app_main">
                    <div className="content-section d-flex flex-column flex-column-fluid">
                        <div id="kt_app_content" className="app-content flex-column-fluid">
                            <div id="kt_app_content_container" className="app-container container-fluid">
                                <div className="card">
                                    <div className="card-header d-flex justify-content-between align-items-center">
                                        <h2 className="card-title fw-bold">
                                            {isAuthenticated ? 'Scheduled Tasks' : 'Calendar'}
                                        </h2>
                                        {!isAuthenticated && <div className="card-toolbar d-flex gap-3">
                                            <button
                                                className="btn btn-flex btn-primary"
                                                onClick={handleAddEventModalToggle}
                                            >
                                                <FaPlus className="me-1" /> Add Event
                                            </button>
                                        </div>}
                                        {/* <div className="card-toolbar d-flex gap-3">
                                            <button
                                                className="btn btn-flex btn-primary"
                                                onClick={handleAddEventModalToggle}
                                            >
                                                <FaPlus className="me-1" /> Add Event
                                            </button>
                                        </div> */}
                                    </div>
                                    <div className="card-body Scheduler">
                                        {  loading ? (
                                            <div>Loading...</div>
                                        ) : error ? (
                                            <div>Error: {error}</div>
                                        ) : (
                                            <FullCalendar
                                                plugins= {[dayGridPlugin, timeGridPlugin]}
                                                initialView="timeGridWeek"
                                                events={events}
                                                headerToolbar={{
                                                    left: "prev,next today",
                                                    center: "title",
                                                    right: "dayGridMonth,timeGridWeek,timeGridDay",
                                                }}
                                                buttonText={{
                                                    today: "Today",
                                                    month: "Month",
                                                    week: "Week",
                                                    day: "Day"
                                                }}
                                                allDayText="all-day"
                                                scrollTime={"08:00:00"}
                                                height="700px"
                                            />
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <AddEventModal
                    show={showAddEventModal}
                    onClose={handleAddEventModalToggle}
                    onSubmit={handleEventSubmit}
                />

                <Footer />
            </div>
        </div>
    );
}

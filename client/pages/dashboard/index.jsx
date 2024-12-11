import React, { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import Header from '../../components/common/Header';
import Footer from '../../components/common/Footer';
import Sidebar from '../../components/common/Sidebar';
import { useTheme } from '../../context/ThemeContext';
import 'leaflet/dist/leaflet.css';
import styles from './Dashboard.module.scss';
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

// Import and register Chart.js components
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

// Dynamically import components that require `window`
const Bar = dynamic(() => import('react-chartjs-2').then(mod => mod.Bar), { ssr: false });
const MapContainer = dynamic(() => import('react-leaflet').then(mod => mod.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import('react-leaflet').then(mod => mod.TileLayer), { ssr: false });
const Marker = dynamic(() => import('react-leaflet').then(mod => mod.Marker), { ssr: false });
const Popup = dynamic(() => import('react-leaflet').then(mod => mod.Popup), { ssr: false });
const Rating = dynamic(() => import('react-rating'), { ssr: false });

const Dashboard = () => {
  const [collapsed, setCollapsed] = useState(false);
  const [loading, setLoading] = useState(true); // State to handle loading

  // Sample data for the chart
  const chartData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
    datasets: [
      {
        label: 'Monthly Sales',
        data: [300, 400, 200, 500, 700],
        backgroundColor: 'rgba(75, 192, 192, 0.6)',
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    plugins: {
      legend: { position: 'top' },
    },
  };

  // Coordinates for the map
  const position = [37.7749, -122.4194]; // Example: San Francisco coordinates
  const { theme, isDarkMode } = useTheme();

  // Simulate loading data
  useEffect(() => {
    const firstLoad = localStorage.getItem("firstLoad");
    if (!firstLoad) {
      localStorage.setItem("firstLoad", "true");
      const timer = setTimeout(() => setLoading(false), 2000); // Simulate 2s loading
      return () => clearTimeout(timer);
    } else {
      setLoading(false);
    }
  }, []);

  // Entire page Skeleton loader
  if (loading) {
    return (
      <div className={`main-screen ${theme === "system" ? "systemMode" : isDarkMode ? "darkMode" : "lightMode"}`}>
        <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
        <div className={`main-content ${collapsed ? "collapsed" : ""}`}>
          <Header />
          <div className="app-main flex-column flex-row-fluid" id="kt_app_main">
            <div className="content-section d-flex flex-column flex-column-fluid">
              <div id="kt_app_content" className="app-content flex-column-fluid">
                <div id="kt_app_content_container" className="app-container container-fluid">
                  <Skeleton height={50} width="60%" className="mb-4" />
                  <Skeleton height={300} width="100%" className="mb-4" />
                  <Skeleton height={300} width="100%" />
                </div>
              </div>
            </div>
          </div>
          <Footer />
        </div>
      </div>
    );
  }

  // Render the actual content after loading
  return (
    <>
      <div className={`main-screen ${theme === "system" ? "systemMode" : isDarkMode ? "darkMode" : "lightMode"}`}>
        <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
        <div className={`main-content ${collapsed ? 'collapsed' : ''}`}>
          <Header />
          <div className="app-main flex-column flex-row-fluid" id="kt_app_main">
            <div className="content-section d-flex flex-column flex-column-fluid">
              <div id="kt_app_content" className="app-content flex-column-fluid">
                <div id="kt_app_content_container" className="app-container container-fluid">
                  <div className={`${styles.dashboard} ${theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode}`}>
                    <h1 className="fw-bold mb-4">Dashboard</h1>

                    <div className={styles.content}>
                      {/* Chart Section */}
                      <div className={styles.chartSection}>
                        <h2>Sales Overview</h2>
                        <Bar data={chartData} options={chartOptions} />
                      </div>

                      {/* Map Section */}
                      <div className={styles.mapSection}>
                        <h2>Locations</h2>
                        <MapContainer center={position} zoom={10} className={styles.mapContainer}>
                          <TileLayer
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            attribution='&copy; <a href="https://osm.org/copyright">OpenStreetMap</a> contributors'
                          />
                          <Marker position={position}>
                            <Popup>San Francisco</Popup>
                          </Marker>
                        </MapContainer>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <Footer />
        </div>
      </div>
    </>
  );
};

export default Dashboard;

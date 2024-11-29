import React from "react";
import { FaMoon, FaSun } from "react-icons/fa";
import { useTheme } from "../../../context/ThemeContext";
import styles from "./header.module.scss"; // Ensure styles are defined

const ThemeToggle = () => {
  const { isDarkMode, toggleTheme } = useTheme();

  const handleToggle = () => {
    toggleTheme(isDarkMode ? "light" : "dark");
  };

  return (
    <label className={styles.toggleLabel}>
      <input
        className={styles.toggleCheckbox}
        type="checkbox"
        checked={isDarkMode} // Bind the toggle state to dark mode
        onChange={handleToggle} // Handle the theme toggle
      />
      <div className={styles.toggleSlot}>
        {/* Sun Icon */}
        <div className={`${styles.sunIconWrapper} ${!isDarkMode ? styles.activeIconWrapper : ""}`}>
          <FaSun className={styles.themeIcon} />
        </div>
        {/* Moon Icon */}
        <div className={`${styles.moonIconWrapper} ${isDarkMode ? styles.activeIconWrapper : ""}`}>
          <FaMoon className={styles.themeIcon} />
        </div>
      </div>
    </label>
  );
};

export default ThemeToggle;

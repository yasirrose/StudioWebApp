import React from "react";
import { useTheme } from "../../../context/ThemeContext";
import ThemeToggle from "./ThemeToggle";
import styles from "./header.module.scss";

const Header = () => {
  const { theme, isDarkMode, toggleTheme } = useTheme();

  return (
    <header
      className={`${styles.header} ${
        theme === "system"
          ? styles.systemMode
          : isDarkMode
          ? styles.darkMode
          : styles.lightMode
      }`}
    >
      <div className={`${styles.headerTop} d-flex justify-content-between items-center`}>
        <div className="d-flex align-items-center position-relative my-1">
          <div className={styles.logo}>
            <a href="#" className={styles.appSidebarLogo}>
              <div className={styles.iplogoOuter}>
                <div className={styles.iplogoInner}>
                  <div className={styles.iplogoWhitetopleft}>
                    <div className={styles.tlball}></div>
                  </div>
                  <div className={styles.iplogoTopright}></div>
                  <div className={styles.clear}></div>
                  <div className={styles.iplogoMiddleleft}></div>
                  <div className={styles.iplogoMiddleright}></div>
                  <div className={styles.clear}></div>
                  <div className={styles.iplogoBottomleft}></div>
                </div>
              </div>
              <span>Studio</span>
            </a>
          </div>
        </div>
        <ThemeToggle />
      </div>
    </header>
  );
};

export default Header;

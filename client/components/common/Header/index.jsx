import React from "react";
import ProfileDropdown from "./ProfileDropdown";
import { useTheme } from '../../../context/ThemeContext';
import { FaChevronDown, FaSearch, FaPlus, FaFileExport } from 'react-icons/fa';
import styles from "./header.module.scss"; 

const Header = () => {
  const { isDarkMode } = useTheme();
  return (
    <header className={`${styles.header} ${isDarkMode ? styles.darkMode : styles.lightMode}`}>
      <div className={`${styles.headerTop} d-flex justify-content-between items-center`}>
        <div className="d-flex align-items-center position-relative my-1">
          <div className="search-field position-relative w-250px">
            <FaSearch className="position-absolute top-50 start-0 translate-middle-y" />
            <input
              type="text"
              placeholder="Search..."
              className="form-control ps-5"
              onChange={e => console.log(e.target.value)}
            />
          </div>
        </div>
        <ProfileDropdown />
      </div>
    </header>
  );
};

export default Header;

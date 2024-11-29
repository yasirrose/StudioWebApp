import { createContext, useContext, useState } from "react";

const PermissionsContext = createContext();

export const PermissionsProvider = ({ children }) => {
    const [menuPermissions, setMenuPermissions] = useState([]);

    const updatePermissions = (permissions) => {
        setMenuPermissions(permissions);
    };

    return (
        <PermissionsContext.Provider value={{ menuPermissions, updatePermissions }}>
            {children}
        </PermissionsContext.Provider>
    );
};

export const usePermissions = () => useContext(PermissionsContext);

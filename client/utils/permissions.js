export const hasAccess = (menuPermissions, path, roleId) => {
    // Format path to match the format in menuPermissions
    const formattedPath = path
        .replace("/", "") // Remove leading "/"
        .toLowerCase()    // Make lowercase to match MENU_NAME formatting
        .replace(/([A-Z])/g, (match) => ` ${match.toLowerCase()}`) // Add spaces before uppercase letters
        .replace(/\s+/g, ''); // Remove any extra spaces
    
    // Check if the formatted path exists in the menu permissions for the given role
    const menu = menuPermissions.find(
        (menu) =>
            formattedPath === menu.MENU_NAME.toLowerCase().replace(/\s+/g, "") &&
            menu.ROLES.some(role => role.ROLE_ID === parseInt(roleId) && role.HAS_ACCESS === 1)
    );

    return !!menu; // Return true if the menu is found and the user has access
};

import React, { useState, useEffect } from 'react';
import Header from '../../components/common/Header';
import Footer from '../../components/common/Footer';
import Sidebar from '../../components/common/Sidebar';
import DataTable from 'react-data-table-component';
import AddTaskModal from '../../components/Shared/AddTaskModal';
import { useTasks, useAddUpdateTask } from '/hooks/tasks';
import styles from '../users/users.module.scss';
import { useRouter } from 'next/router';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { FaChevronDown, FaSearch, FaPlus, FaFileExport } from 'react-icons/fa';
import { useFetchUsers } from '/hooks/users';
import { useFetchProjects } from '/hooks/projects';
import { useFetchStatuses } from '/hooks/taskStatuses';
import Select from 'react-select';  // Import react-select
import { useTheme } from '../../context/ThemeContext';
import { format } from 'date-fns'; // Import date-fns for date formatting
import { useFetchActionPermissions } from "../../hooks/permissions";

const Tasks = () => {
    const router = useRouter();
    const { query } = router;
    const project_id = query.project_id;
    
    const { addUpdateTask } = useAddUpdateTask();
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState(''); // New state for status filter
    const [projectFilter, setProjectFilter] = useState(''); // New state for project filter
    const [showModal, setShowModal] = useState(false);
    const [modalMode, setModalMode] = useState(''); // 'add' or 'edit'
    const [selectedTask, setSelectedTask] = useState(null);
    const [filteredTasks, setFilteredTasks] = useState([]);
    const [isFiltering, setIsFiltering] = useState(true);
    const [roleId, setRoleId] = useState(null);

    const { Users, loading:loadingUsers } = useFetchUsers();
    const { Projects, loading:loadingProjects } = useFetchProjects();
    const { Statuses, loading:loadingStatuses } = useFetchStatuses();
    const { Tasks: allTasks, loading, error, setTasks } = useTasks();
    const { actionPermissions } = useFetchActionPermissions();
    const [openDropdownId, setOpenDropdownId] = useState(null);

    const handleProjectFilterChange = (e) => {
        console.log("----E = ", e);
        
        // const selectedProject = e.target.value;
        const selectedProject = e.value;
        setProjectFilter(selectedProject);
        router.replace(router.pathname, undefined, { shallow: true });
    };

    // Set projectFilter based on project_id in the URL once Projects have loaded
    useEffect(() => {
        if (Projects && project_id) {
            const selectedProject = Projects.find(
                (project) => project.project_id.toString() === project_id.toString()
            );
            if (selectedProject) {
                setProjectFilter(selectedProject.project_name); // Set the project name as the filter
            }
        }
    }, [Projects, project_id]);

    useEffect(() => {
        
        if (allTasks) {
            if (project_id) {
                setIsFiltering(true);
                
                const filteredList = allTasks.filter(task => task.project_id.toString() === project_id.toString());
                setFilteredTasks(filteredList);
                setIsFiltering(false);
            } else {
                setIsFiltering(false);
                setFilteredTasks(allTasks);
            }
        }
    }, [allTasks, project_id]);

    useEffect(() => {
        const storedRoleId = localStorage.getItem("roleId");
        setRoleId(parseInt(storedRoleId, 10)); // Parse roleId from localStorage
    }, []);

    const hasAccessToAction = (menuName, actionName) => {
        // Find the menu object with the given MENU_NAME and ACTION_NAME
        const action = actionPermissions?.find(
            item => item.MENU_NAME === menuName && item.ACTION_NAME === actionName
        );

        // Check if the user's role has access to this action
        const role = action?.ROLES.find(role => role.ROLE_ID === roleId);
        return role?.HAS_ACCESS === 1; // Return true if the role has access
    };

    const canAddTask = hasAccessToAction("Project Tasks", "Task -> Add Task");
    const canEditTask = hasAccessToAction("Project Tasks", "Task -> Update Task");
    const canDeleteTask = hasAccessToAction("Project Tasks", "Task -> Delete Task");

    const handleAddTask = () => {
        setSelectedTask(null);
        setModalMode('add');
    };

    const handleEditTask = (task) => {
        setSelectedTask(task);
        setModalMode('edit');
    };

    const displayedTasks = filteredTasks
        .filter(task => 
            task.task_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            task.assigned_user_name.toLowerCase().includes(searchTerm.toLowerCase())
        )
        .filter(task => (statusFilter ? task.task_status === statusFilter : true))
        .filter(task => (projectFilter ? task.project_name === projectFilter : true));

    const columns = [
        {
            name: 'Name',
            selector: row => row.task_name,
            sortable: true,
        },
        {
            name: 'Project',
            selector: row => row.project_name,
            sortable: true,
        },
        {
            name: 'Assigned To',
            selector: row => row.assigned_user_name,
            sortable: true,
        },
        {
            name: 'Start Date',
            selector: row => {
                if (row.task_start_date) {
                    // Format the date to "MMM dd, yyyy"
                    const formattedDate = format(new Date(row.task_start_date), 'MMM dd, yyyy');
                    return formattedDate;
                }
                return 'N/A'; // Handle cases where the date is not available
            },
            sortable: true,
        },
        {
            name: 'End Date',
            selector: row => {
                if (row.task_end_date) {
                    const formattedDate = format(new Date(row.task_end_date), 'MMM dd, yyyy');
                    return formattedDate;
                }
                return 'N/A';
            },
            sortable: true,
        },
        {
            name: 'Status',
            selector: row => (
                <span className={`badge ${
                    row.task_status === 'Completed' ? 'badge-light-success' :
                    row.task_status === 'In Progress' ? 'badge-info-light' :
                    row.task_status === 'Pending' ? 'badge-warning-light' :
                    row.task_status === 'Testing' ? 'badge-primary-light' :
                    row.task_status === 'On Hold' ? 'badge-light-danger' : ''
                }`}>
                    {row.task_status}
                </span>
            ),
            sortable: true,
        },
        {
            name: "Actions",
            cell: row => {
        
                useEffect(() => {
                    const handleOutsideClick = (event) => {
                        if (!event.target.closest(`#dropdown-${row.task_id}`)) {
                            setOpenDropdownId(null);
                        }
                    };
        
                    document.addEventListener('click', handleOutsideClick);
                    return () => document.removeEventListener('click', handleOutsideClick);
                }, [row.task_id]);
        
                return (
                    <div
                        id={`dropdown-${row.task_id}`}
                        className={`${styles.dropdown} ${isDarkMode ? styles.darkDropdown : styles.lightDropdown}`}
                        onClick={e => e.stopPropagation()}
                    >
                        <button
                            className={`${styles.dropdownButton} ${
                                isDarkMode ? styles.darkButton : styles.lightButton
                            }`}
                            onClick={() =>
                                setOpenDropdownId(prevId => (prevId === row.task_id ? null : row.task_id))
                            }
                        >
                            Actions <FaChevronDown className={styles.dropdownIcon} />
                        </button>
                        {openDropdownId === row.task_id && (
                            <div className={`${styles.dropdownContent} ${isDarkMode ? styles.darkDropdown : styles.lightDropdown}`}>
                                {canEditTask && (
                                    <button
                                        data-bs-toggle="modal"
                                        data-bs-target="#kt_modal_add_task"
                                        onClick={() => handleEditTask(row)}
                                    >
                                        Edit Task
                                    </button>
                                )}
                            </div>
                        )}
                    </div>
                );
            },
        }
        
    ];

    const [collapsed, setCollapsed] = useState(false);
    const { isDarkMode } = useTheme();

    return (
        <div className={`main-screen ${isDarkMode ? 'darkMode' : 'lightMode'}`}>
            <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
            <div className={`main-content ${collapsed ? 'collapsed' : ''}`}>
                <Header />
                <div className="app-main flex-column flex-row-fluid" id="kt_app_main">
                    <div className="content-section d-flex flex-column flex-column-fluid">
                        <ToastContainer />
                        <div id="kt_app_content" className="app-content flex-column-fluid">
                            <div id="kt_app_content_container" className="app-container container-fluid">
                                <div className="app-toolbar-wrapper d-flex flex-stack flex-wrap gap-4 w-100">
                                    <div className="page-title d-flex flex-column justify-content-center gap-1 me-3">
                                        <h1 className="page-heading d-flex flex-column justify-content-center text-gray-900 fw-bold fs-3 m-0">
                                            Project Tasks
                                        </h1>
                                        <ul className="breadcrumb breadcrumb-separatorless fw-semibold fs-7 my-0">
                                            <li className="breadcrumb-item text-muted">
                                                <a href="/" className="text-muted text-hover-primary">Home</a>
                                            </li>
                                            <li className="breadcrumb-item">
                                                <span className="bullet bg-gray-500 w-5px h-2px"></span>
                                            </li>
                                            <li className="breadcrumb-item text-muted">Project Tasks</li>
                                        </ul>
                                    </div>
                                </div>
                                <div className="card mt-5">
                                    <div className="card-header border-0 pt-6">
                                        <div className="card-title">
                                            <div className="d-flex align-items-center position-relative my-1">
                                                <div className="search-field position-relative w-250px">
                                                    <FaSearch className="position-absolute top-50 start-0 translate-middle-y" />
                                                    <input
                                                        type="text"
                                                        placeholder="Search Tasks"
                                                        className="form-control form-control-solid ps-5"
                                                        onChange={e => setSearchTerm(e.target.value)}
                                                    />
                                                </div>
                                            </div>
                                            <div className="status-filter ms-3 position-relative w-250px">
                                                <Select
                                                    className="custom-dropdown"
                                                    options={[
                                                        { value: null, label: 'Select Project' }, // "None" option represents no project selection
                                                        ...(Statuses && Statuses.length > 0 ? Statuses.map(status => ({
                                                            value: status.status_name,
                                                            label: status.status_name
                                                        })) : []) // Only map if Statuses is not null or empty
                                                    ]}
                                                    value={statusFilter ? { value: statusFilter, label: statusFilter } : null}
                                                    onChange={e => setStatusFilter(e.value)}
                                                    placeholder="Select Task Status"
                                                    isSearchable={true}
                                                /> 
                                            </div>

                                            <div className="project-filter ms-3 position-relative w-250px">
                                                <Select
                                                    className="custom-dropdown"
                                                    options={[
                                                        { value: null, label: 'Select Project' }, // "None" option represents no project selection
                                                        ...(Projects && Projects.length > 0 ? Projects.map(project => ({
                                                            value: project.project_name,
                                                            label: project.project_name
                                                        })) : []) // Only map if Projects is not null or empty
                                                    ]}
                                                    value={projectFilter ? { value: projectFilter, label: projectFilter } : null}
                                                    onChange={handleProjectFilterChange}
                                                    placeholder="Select Project"
                                                    isSearchable={true}
                                                />
                                            </div>
                                        </div>
                                        <div className="card-toolbar d-flex gap-3">
                                            <button className="btn btn-light-primary">
                                                <FaFileExport className="me-1" /> Export
                                            </button>
                                            { canAddTask && (
                                                <button className="btn btn-primary" data-bs-toggle="modal" data-bs-target="#kt_modal_add_task" onClick={handleAddTask}>
                                                    <FaPlus className="me-1" /> Add New
                                                </button>
                                            )}
                                        </div>
                                    </div>
                                    <div className="card-body pt-0">
                                        { isFiltering || loading ? (
                                            <div>Loading...</div>
                                        ) : error ? (
                                            <div>Error: {error}</div>
                                        ) : (
                                            <DataTable
                                                columns={columns}
                                                data={displayedTasks}
                                                paginationPerPage={5}
                                                pagination
                                                highlightOnHover
                                                responsive
                                                defaultSortField="task_name"
                                                className='data-table-view'
                                            />
                                        )}
                                    </div>
                                </div>
                                { !loadingUsers && !loadingStatuses && !loadingProjects && (
                                    <AddTaskModal
                                        mode={modalMode}
                                        taskData={selectedTask}
                                        addUpdateTask={addUpdateTask}
                                        setTasks={setTasks}
                                        setShowModal={setShowModal}
                                        Users={Users}
                                        Projects={Projects}
                                        Statuses={Statuses}
                                    />
                                )}
                            </div>
                        </div>
                    </div>
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default Tasks;

import React, { useState, useEffect } from 'react';
import Select from 'react-select';  // Import react-select
// import DatePicker from 'react-datepicker';
// import 'react-datepicker/dist/react-datepicker.css';

// import TimePicker from 'react-time-picker';
// // import './TaskTimePicker.css'; // Custom CSS file for styling

const AddTaskModal = ({ mode, Users, Statuses, Projects, setTasks, taskData = {}, addUpdateTask }) => {
    // Existing state variables
    const [taskName, setTaskName] = useState('');
    const [description, setDescription] = useState('');
    const [assignedTo, setAssignedTo] = useState('');
    const [statusId, setStatusId] = useState('');
    const [projectId, setProjectId] = useState('');
    const [taskId, setTaskId] = useState('');
    const [errors, setErrors] = useState({});

    // New state variables for the added fields
    const [taskStartDate, setTaskStartDate] = useState('');
    const [taskStartTime, setTaskStartTime] =  useState('14:00');
    const [taskEndDate, setTaskEndDate] = useState('');
    const [taskEndTime, setTaskEndTime] = useState('');
    const [allDay, setAllDay] = useState(false);
    // const [amPm, setAmPm] = useState('PM'); // Default to PM
    // Filter to only include admin users
    const clientUsers = Users?.filter(user => user.role_name === 'Client User');

    // console.log("---clientUsers = ", clientUsers);
    

    useEffect(() => {
        if (mode === 'edit' && taskData) {
            setTaskName(taskData.task_name);
            setDescription(taskData.description);
            setAssignedTo(taskData.assigned_to);
            setStatusId(taskData.status_id);
            setProjectId(taskData.project_id);
            setTaskId(taskData.task_id);

            // Set new fields if they exist in taskData
            setTaskStartDate(taskData.task_start_date || '');
            setTaskStartTime(taskData.task_start_time || '');
            setTaskEndDate(taskData.task_end_date || '');
            setTaskEndTime(taskData.task_end_time || '');
            setAllDay(taskData.all_day || false);
        } else {
            resetForm();
        }
    }, [mode, taskData]);

    const resetForm = () => {
        setTaskName('');
        setDescription('');
        setAssignedTo('');
        setStatusId();
        setProjectId('');
        setTaskId();
        setTaskStartDate('');
        setTaskStartTime('');
        setTaskEndDate('');
        setTaskEndTime('');
        setAllDay(false);
        setErrors({});
    };

    const handleAllDayChange = (e) => {
        setAllDay(e.target.checked);
        if (e.target.checked) {
            setTaskStartTime('');
            setTaskEndTime('');
        }
    };

    const validateForm = () => {
        const newErrors = {};
        if (!taskName.trim()) newErrors.taskName = "Task name is required.";
        if (!assignedTo) newErrors.assignedTo = "Assignee is required.";
        if (!projectId) newErrors.projectId = "Project selection is required.";
        if (!taskStartDate) newErrors.taskStartDate = 'Start date is required';
        if (!taskEndDate) newErrors.taskEndDate = 'End date is required';
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        if (!validateForm()) return;

        const taskDataToSubmit = {
            task_id: taskId,
            project_id: projectId,
            task_name: taskName,
            description: description,
            assigned_to: assignedTo,
            status_id: statusId,
            task_start_date: taskStartDate,
            task_start_time: allDay ? null : taskStartTime,
            task_end_date: taskEndDate,
            task_end_time: allDay ? null : taskEndTime,
            all_day: allDay,
        };

        addUpdateTask(taskDataToSubmit, setTasks);
        document.querySelector("#kt_modal_add_task .btn-close").click();
        resetForm();
    };


    // Handle time change and AM/PM toggle
    const handleTimeChange = (time) => {
        const [hour, minute] = time.split(':');
        if (hour < 12 && amPm === 'PM') {
            setTaskStartTime(`${parseInt(hour) + 12}:${minute}`);
        } else if (hour >= 12 && amPm === 'AM') {
            setTaskStartTime(`${parseInt(hour) - 12}:${minute}`);
        } else {
            setTaskStartTime(time);
        }
    };

    // Toggle AM/PM on click
    const toggleAmPm = () => {
        setAmPm((prev) => (prev === 'AM' ? 'PM' : 'AM'));
        const [hour, minute] = taskStartTime.split(':');
        setTaskStartTime(`${(parseInt(hour) % 12) + (amPm === 'AM' ? 12 : 0)}:${minute}`);
    };

    return (
        <div className="modal fade" id="kt_modal_add_task" tabIndex="-1" aria-hidden="true">
            <div className="modal-dialog modal-dialog-centered mw-650px">
                <div className="modal-content">
                    <form onSubmit={handleSubmit}>
                        <div className="modal-header">
                            <h2 className="modal-title">{mode === 'edit' ? 'Edit Task' : 'Add Task'}</h2>
                            <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close" onClick={resetForm}></button>
                        </div>
                        <div className="modal-body">
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold required">Task Name</label>
                                <input
                                    type="text"
                                    className={`form-control form-control-solid ${errors.taskName ? 'is-invalid' : ''}`}
                                    value={taskName}
                                    name="taskName"
                                    onChange={(e) => { setTaskName(e.target.value); if (errors.taskName) setErrors(prev => ({ ...prev, taskName: '' })); }}
                                />
                                {errors.taskName && <span className="text-danger">{errors.taskName}</span>}
                            </div>
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold">Description</label>
                                <textarea
                                    className="form-control form-control-solid"
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                />
                            </div>


                            <div className="fv-row mb-7">
                                <label className="required fs-6 fw-semibold mb-2">Select Project</label>
                                <Select
                                options={
                                    Projects?.map(project => ({
                                    value: project.project_id,
                                    label: project.project_name,
                                }))}
                                value={Projects?.find(project => project.project_id === projectId) && {
                                    value: projectId,
                                    label: Projects.find(project => project.project_id === projectId)?.project_name,
                                }}
                                onChange={(option) => { setProjectId(option?.value || ''); if (errors.projectId) setErrors(prev => ({ ...prev, projectId: '' })); }}
                                classNamePrefix="react-select"
                                className={errors.projectId ? 'is-invalid' : ''}
                                placeholder="Select project"
                                />
                                {errors.projectId && <span className="text-danger">{errors.projectId}</span>}
                            </div>

                            <div className="fv-row mb-7">
                                <label className="required fs-6 fw-semibold mb-2">Assigned To</label>
                                <Select
                                    options={clientUsers?.map(client => ({
                                    value: client.user_id,
                                    label: `${client.first_name} ${client.last_name}`,
                                    }))}
                                    value={clientUsers?.find(client => client.user_id === assignedTo) && {
                                    value: assignedTo,
                                    label: clientUsers.find(client => client.user_id === assignedTo)?.first_name + ' ' +
                                            clientUsers.find(client => client.user_id === assignedTo)?.last_name,
                                    }}
                                    onChange={(option) => { setAssignedTo(option?.value || ''); if (errors.assignedTo) setErrors(prev => ({ ...prev, assignedTo: '' })); }}
                                    classNamePrefix="react-select"
                                    className={errors.assignedTo ? 'is-invalid' : ''}
                                    placeholder="Select Assignee"
                                />
                                {errors.assignedTo && <span className="text-danger">{errors.assignedTo}</span>}
                            </div>

                            <div className="fv-row mb-7">
                                <label className="fs-6 fw-semibold mb-2">Task Status</label>
                                <Select
                                options={Statuses?.map(status => ({
                                    value: status.status_id,
                                    label: status.status_name,
                                }))}
                                value={Statuses?.find(status => status.status_id === statusId) && {
                                    value: statusId,
                                    label: Statuses.find(status => status.status_id === statusId)?.status_name,
                                }}
                                onChange={(option) => setStatusId(option?.value || '')}
                                classNamePrefix="react-select"
                                placeholder="Select Status"
                                />
                            </div>
                            {/* New fields */}
                            <div className="form-group mb-3">
                                <input
                                    type="checkbox"
                                    id="allDay"
                                    checked={allDay}
                                    onChange={handleAllDayChange}
                                />
                                <label htmlFor="allDay" className="ms-2">All Day</label>
                            </div>
                            <div className="row">
                                <div className="col-md-6">
                                    <div className="form-group mb-9">
                                        <label className="fs-6 fw-semibold required">Task Start Date</label>
                                        <input
                                            type="date"
                                            className={`form-control form-control-solid ${errors.taskStartDate ? 'is-invalid' : ''}`}
                                            value={taskStartDate}
                                            onChange={(e) => { setTaskStartDate(e.target.value); if (errors.taskStartDate) setErrors(prev => ({ ...prev, taskStartDate: '' })); }}
                                        />
                                        {errors.taskStartDate && <span className="text-danger">{errors.taskStartDate}</span>}
                                    </div>
                                </div>
                                <div className="col-md-6">
                                    {!allDay && (
                                        <div className="form-group mb-9">
                                            <label className="fs-6 fw-semibold">Task Start Time</label>
                                            <input
                                                type="time"
                                                className="form-control form-control-solid"
                                                value={taskStartTime}
                                                onChange={(e) => setTaskStartTime(e.target.value)}
                                            />
                                        </div>
                                    )}
                                </div>
                                <div className="col-md-6">
                                    <div className="form-group mb-9">
                                        <label className="fs-6 fw-semibold required">Task End Date</label>
                                        <input
                                            type="date"
                                            className={`form-control form-control-solid ${errors.taskEndDate ? 'is-invalid' : ''}`}
                                            value={taskEndDate}
                                            onChange={(e) => { setTaskEndDate(e.target.value); if (errors.taskEndDate) setErrors(prev => ({ ...prev, taskEndDate: '' })); }}

                                        />
                                        {errors.taskEndDate && <span className="text-danger">{errors.taskEndDate}</span>}
                                    </div>
                                </div>
                                <div className="col-md-6">
                                    {!allDay && (
                                        <div className="form-group mb-9">
                                            <label className="fs-6 fw-semibold">Task End Time</label>
                                            <input
                                                type="time"
                                                className="form-control form-control-solid"
                                                value={taskEndTime}
                                                onChange={(e) => setTaskEndTime(e.target.value)}
                                            />
                                        </div>
                                    )}
                                </div>

                                {/* <div className="task-time-picker">
                                    <label>Task Start Time</label>
                                    <div className="time-picker-container">
                                        <TimePicker
                                            onChange={handleTimeChange}
                                            value={taskStartTime}
                                            format="h:mm a" // Keep format for consistency
                                            clearIcon={null} // Hide the clear icon
                                            clockIcon={null} // Hide the clock icon
                                            disableClock={true} // Disable clock view
                                        />
                                        <span className="am-pm-toggle" onClick={toggleAmPm}>
                                            {amPm}
                                        </span>
                                    </div>
                                </div> */}

                            </div>
                            {/* Other existing fields go here */}
                        </div>
                        <div className="modal-footer">
                            <button type="button" className="btn btn-light" data-bs-dismiss="modal" onClick={resetForm}>Cancel</button>
                            <button type="submit" className="btn btn-primary">{mode === 'edit' ? 'Update' : 'Add'}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default AddTaskModal;

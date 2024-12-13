import React, { useState, useEffect } from 'react';
import Select from 'react-select';  // Import react-select
import DatePicker from "react-multi-date-picker";
import TimePicker from "react-multi-date-picker/plugins/time_picker";

const AddTaskModal = ({ mode, Users, Statuses, Projects, setTasks, taskData = {}, addUpdateTask }) => {
    // Combine all state variables into a single state object
    const [task, setTask] = useState({
        taskName: '',
        description: '',
        assignedTo: '',
        statusId: '',
        projectId: '',
        taskId: '',
        taskStartDate: '',
        taskStartTime: '14:00',
        taskEndDate: '',
        taskEndTime: '',
        allDay: false,
    });

    const [errors, setErrors] = useState({});

    // Filter to only include admin users
    const clientUsers = Users?.filter(user => user.role_name === 'Client User');

    useEffect(() => {
        if (mode === 'edit' && taskData) {
            // Parse the date strings into Date objects
            const startDate = taskData.task_start_date ? new Date(taskData.task_start_date) : '';
            const endDate = taskData.task_end_date ? new Date(taskData.task_end_date) : '';

            setTask({
                taskName: taskData.task_name,
                description: taskData.description,
                assignedTo: taskData.assigned_to,
                statusId: taskData.status_id,
                projectId: taskData.project_id,
                taskId: taskData.task_id || '',
                taskStartDate: startDate || '',
                taskStartTime: taskData.task_start_time || '14:00',
                taskEndDate: endDate || '',
                taskEndTime: taskData.task_end_time || '14:00',
                allDay: taskData.all_day || false,
            });
            console.log("--- taskData.task_start_date---",  taskData.task_start_date);
        } else {
            resetForm();
        }
    }, [mode, taskData]);

    console.log("---taskEndDate", task.taskEndDate);

    

    const resetForm = () => {
        setTask({
            taskName: '',
            description: '',
            assignedTo: '',
            statusId: '',
            projectId: '',
            taskId: undefined,
            taskStartDate: '',
            taskStartTime: '',
            taskEndDate: '',
            taskEndTime: '',
            allDay: false,
        });
        setErrors({});
    };

    const handleAllDayChange = (e) => {
        const updatedTask = { ...task, allDay: e.target.checked };
        if (e.target.checked) {
            updatedTask.taskStartTime = '';
            updatedTask.taskEndTime = '';
        }
        setTask(updatedTask);
    };

    const validateForm = () => {
        const newErrors = {};
        if (!task.taskName.trim()) newErrors.taskName = "Task name is required.";
        if (!task.assignedTo) newErrors.assignedTo = "Assignee is required.";
        if (!task.projectId) newErrors.projectId = "Project selection is required.";
        if (!task.taskStartDate) newErrors.taskStartDate = 'Start date is required';
        if (!task.taskEndDate) newErrors.taskEndDate = 'End date is required';
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        if (!validateForm()) return;

        const taskDataToSubmit = {
            task_id: task.taskId,
            project_id: task.projectId,
            task_name: task.taskName,
            description: task.description,
            assigned_to: task.assignedTo,
            status_id: task.statusId,
            task_start_date: task.taskStartDate,
            task_start_time: task.allDay ? null : task.taskStartTime,
            task_end_date: task.taskEndDate,
            task_end_time: task.allDay ? null : task.taskEndTime,
            all_day: task.allDay,
        };

        addUpdateTask(taskDataToSubmit, setTasks);
        document.querySelector("#kt_modal_add_task .btn-close").click();
        resetForm();
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
                                    value={task.taskName}
                                    name="taskName"
                                    onChange={(e) => { setTask({ ...task, taskName: e.target.value }); if (errors.taskName) setErrors(prev => ({ ...prev, taskName: '' })); }}
                                />
                                {errors.taskName && <span className="text-danger">{errors.taskName}</span>}
                            </div>
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold">Description</label>
                                <textarea
                                    className="form-control form-control-solid"
                                    value={task.description}
                                    onChange={(e) => setTask({ ...task, description: e.target.value })}
                                />
                            </div>

                            <div className="fv-row mb-7">
                                <label className="required fs-6 fw-semibold mb-2">Select Project</label>
                                <Select
                                    options={Projects?.map(project => ({
                                        value: project.project_id,
                                        label: project.project_name,
                                    }))}
                                    value={Projects?.find(project => project.project_id === task.projectId) && {
                                        value: task.projectId,
                                        label: Projects.find(project => project.project_id === task.projectId)?.project_name,
                                    }}
                                    onChange={(option) => { setTask({ ...task, projectId: option?.value || '' }); if (errors.projectId) setErrors(prev => ({ ...prev, projectId: '' })); }}
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
                                    value={clientUsers?.find(client => client.user_id === task.assignedTo) && {
                                        value: task.assignedTo,
                                        label: `${clientUsers.find(client => client.user_id === task.assignedTo)?.first_name} ${clientUsers.find(client => client.user_id === task.assignedTo)?.last_name}`,
                                    }}
                                    onChange={(option) => { setTask({ ...task, assignedTo: option?.value || '' }); if (errors.assignedTo) setErrors(prev => ({ ...prev, assignedTo: '' })); }}
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
                                    value={Statuses?.find(status => status.status_id === task.statusId) && {
                                        value: task.statusId,
                                        label: Statuses.find(status => status.status_id === task.statusId)?.status_name,
                                    }}
                                    onChange={(option) => setTask({ ...task, statusId: option?.value || '' })}
                                    classNamePrefix="react-select"
                                    placeholder="Select Status"
                                />
                            </div>

                            {/* All Day Checkbox */}
                            <div className="form-group mb-9">
                                <label className="form-check form-check-custom form-check-solid">
                                <input
                                    type="checkbox"
                                    className="form-check-input"
                                    checked={task.allDay}
                                    onChange={handleAllDayChange}
                                />
                                <span className="form-check-label fw-semibold">All Day</span>
                                </label>
                            </div>

                            {/* Event Dates and Times */}
                            <div className="row">
                                <div className="col-md-6">
                                    <div className="form-group mb-9">
                                        <label className="fs-6 fw-semibold required">Task Start Date</label>
                                        <DatePicker
                                            value={task.taskStartDate}
                                            placeholder="MM/DD/YYYY"
                                            onChange={(date) => {  setTask({ ...task, taskStartDate: date }); if (errors.taskStartDate) setErrors(prev => ({ ...prev, taskStartDate: '' })); }}
                                            format="MM/DD/YYYY"
                                        />
                                        {errors.taskStartDate && <span className="text-danger">{errors.taskStartDate}</span>}
                                    </div>
                                </div>
                                <div className="col-md-6">
                                    {!task.allDay && (
                                        <div className="form-group mb-9">
                                            <label className="fs-6 fw-semibold">Task Start Time</label>
                                            <DatePicker
                                                disableDayPicker
                                                format="hh:mm A"
                                                placeholder="HH:MM"
                                                plugins={[<TimePicker hideSeconds />]}
                                                value={task.taskStartTime}
                                                onChange={(time) => setTask({ ...task, taskStartTime: time })}
                                            />
                                        </div>
                                    )}
                                </div>

                                <div className="col-md-6">
                                    <div className="form-group mb-9">
                                        <label className="fs-6 fw-semibold required">Task End Date</label>
                                        <DatePicker
                                            value={task.taskEndDate}
                                            placeholder="MM/DD/YYYY"
                                            onChange={(date) => {  setTask({ ...task, taskEndDate: date }); if (errors.taskEndDate) setErrors(prev => ({ ...prev, taskEndDate: '' })); }}
                                            format="MM/DD/YYYY"
                                        />
                                        {errors.taskEndDate && <span className="text-danger">{errors.taskEndDate}</span>}
                                    </div>
                                </div>
                                <div className="col-md-6">
                                    {!task.allDay && (
                                        <div className="form-group mb-9">
                                            <label className="fs-6 fw-semibold">Task End Time</label>
                                            <DatePicker
                                                disableDayPicker
                                                format="hh:mm A"
                                                placeholder="HH:MM"
                                                plugins={[<TimePicker hideSeconds />]}
                                                value={task.taskEndTime}
                                                onChange={(time) => setTask({ ...task, taskEndTime: time })}
                                            />
                                        </div>
                                    )}
                                </div>
                            </div>

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

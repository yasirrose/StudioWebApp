import React, { useState, useEffect } from 'react';
import { toast } from 'react-toastify';

const AddProjectModal = ({ mode, Clients, setProjects, projectData = {}, addUpdateProject }) => {
    const [projectName, setProjectName] = useState('');
    const [asanaProjectName, setAsanaProjectName] = useState('');
    const [asanaApiClientID, setAsanaApiClientID] = useState('');
    const [asanaApiClientSecret, setAsanaApiClientSecret] = useState('');
    const [projectId, setProjectId] = useState('');
    const [clientId, setClientId] = useState('');
    const [errors, setErrors] = useState({});

    // Populate form fields if in "edit" mode
    useEffect(() => {
        if (mode === 'edit' && projectData) {
            setProjectName(projectData.project_name);
            setAsanaProjectName(projectData.asana_project_name);
            setAsanaApiClientID(projectData.asana_api_client_id);
            setAsanaApiClientSecret(projectData.asana_api_client_secret);
            setClientId(projectData.client_id);
            setProjectId(projectData.project_id);
        } else {
            resetForm();
        }
    }, [mode, projectData]);

    const resetForm = () => {
        setProjectName('');
        setAsanaProjectName('');
        setAsanaApiClientID('');
        setAsanaApiClientSecret('');
        setClientId('');
        setProjectId();
        setErrors({});
    };

    // Validation function
    const validateForm = () => {
        const newErrors = {};
        if (!projectName.trim()) newErrors.projectName = "Project name is required.";
        if (!asanaProjectName.trim()) newErrors.asanaProjectName = "Asana project name is required.";
        if (!asanaApiClientID.trim()) newErrors.asanaApiClientID = "Asana API client ID is required.";
        if (!asanaApiClientSecret.trim()) newErrors.asanaApiClientSecret = "Asana API client secret is required.";
        if (!clientId) newErrors.clientId = "Project Client is required.";
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        if (value.trim()) {
            setErrors(prev => ({ ...prev, [name]: '' })); // Clear specific error on input change
        }
    };

    const handleSubmit = (e) => {
        e.preventDefault();

        // Validate the form before submitting
        if (!validateForm()) return;

        const projectDataToSubmit = {
            client_id: clientId,
            project_id: projectId,
            project_name: projectName,
            asana_project_name: asanaProjectName,
            asana_api_client_id: asanaApiClientID,
            asana_api_client_secret: asanaApiClientSecret,
        };

        // Call addUpdateProject API
        addUpdateProject(projectDataToSubmit, setProjects);
        document.querySelector("#kt_modal_add_project .btn-close").click();
        resetForm();
    };

    return (
        <div className="modal fade" id="kt_modal_add_project" tabIndex="-1" aria-hidden="true">
            <div className="modal-dialog modal-dialog-centered mw-650px">
                <div className="modal-content">
                    <form onSubmit={handleSubmit}>
                        <div className="modal-header">
                            <h2 className="modal-title">{mode === 'edit' ? 'Edit Project' : 'Add Project'}</h2>
                            <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close" onClick={resetForm}></button>
                        </div>
                        <div className="modal-body">
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold required">Project Name</label>
                                <input
                                    type="text"
                                    name="projectName"
                                    className={`form-control form-control-solid ${errors.projectName ? 'is-invalid' : ''}`}
                                    value={projectName}
                                    onChange={(e) => { setProjectName(e.target.value); handleInputChange(e); }}
                                />
                                {errors?.projectName && <span className="text-danger">{errors?.projectName}</span>}
                            </div>
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold required">Asana Project Name</label>
                                <input
                                    type="text"
                                    name="asanaProjectName"
                                    className={`form-control form-control-solid ${errors.asanaProjectName ? 'is-invalid' : ''}`}
                                    value={asanaProjectName}
                                    onChange={(e) => { setAsanaProjectName(e.target.value); handleInputChange(e); }}
                                />
                                {errors?.asanaProjectName && <span className="text-danger">{errors?.asanaProjectName}</span>}
                            </div>
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold required">Asana API Client ID</label>
                                <input
                                    type="text"
                                    name="asanaApiClientID"
                                    className={`form-control form-control-solid ${errors.asanaApiClientID ? 'is-invalid' : ''}`}
                                    value={asanaApiClientID}
                                    onChange={(e) => { setAsanaApiClientID(e.target.value); handleInputChange(e); }}
                                />
                                {errors?.asanaApiClientID && <span className="text-danger">{errors?.asanaApiClientID}</span>}
                            </div>
                            <div className="form-group mb-9">
                                <label className="fs-6 fw-semibold required">Asana API Client Secret</label>
                                <input
                                    type="text"
                                    name="asanaApiClientSecret"
                                    className={`form-control form-control-solid ${errors.asanaApiClientSecret ? 'is-invalid' : ''}`}
                                    value={asanaApiClientSecret}
                                    onChange={(e) => { setAsanaApiClientSecret(e.target.value); handleInputChange(e); }}
                                />
                                {errors?.asanaApiClientSecret && <span className="text-danger">{errors?.asanaApiClientSecret}</span>}
                            </div>
                            <div className="fv-row mb-7">
                                <label className="required fs-6 fw-semibold mb-2">Client Name</label>
                                <select
                                    className={`form-control form-control-solid ${errors.clientId ? 'is-invalid' : ''}`}
                                    value={clientId}
                                    name="clientId"
                                    onChange={(e) => { setClientId(e.target.value); handleInputChange(e); }}
                                >
                                    <option value="">Select Assign</option>
                                    {Clients?.map(client => (
                                        <option key={client.client_id} value={client.client_id}>
                                            {client.first_name} {client.last_name}
                                        </option>
                                    ))}
                                </select>
                                {errors.clientId && <span className="text-danger">{errors.clientId}</span>}
                            </div>
                        </div>

                        <div className="modal-footer">
                            <button type="reset" className="btn btn-light" data-bs-dismiss="modal" onClick={resetForm}>{mode === 'edit' ? 'Discard Changes' : 'Close'}</button>
                            <button type="submit" className="btn btn-primary">
                                {mode === 'edit' ? 'Save Changes' : 'Save'}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default AddProjectModal;

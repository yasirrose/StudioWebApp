import React, { useState, useEffect } from 'react';

const AddClientModal = ({ addUpdateClient, Users, setClients, mode, clientData = {} }) => {
    const [firstName, setFirstName] = useState('');
    const [lastName, setLastName] = useState('');
    const [email, setEmail] = useState('');
    const [phone, setPhone] = useState('');
    const [clientPin, setClientPin] = useState('');
    const [clientDefaultPage, setClientDefaultPage] = useState('');
    const [selectedAdminId, setSelectedAdminId] = useState('');
    const [client_id, setClientId] = useState('');
    const [errors, setErrors] = useState({});

    // Filter to only include admin users
    const adminUsers = Users?.filter(user => user.role_name === 'Admin');

    useEffect(() => {
        if (mode === 'edit' && clientData) {
            setFirstName(clientData.first_name);
            setLastName(clientData.last_name);
            setEmail(clientData.email);
            setPhone(clientData.phone);
            setClientPin(clientData.client_pin);
            setClientDefaultPage(clientData.client_default_page);
            setSelectedAdminId(clientData.client_main_id);
            setClientId(clientData.client_id);
        } else if (mode === 'add') {
            // Reset fields for 'add' mode
            // resetForm();
        }
    }, [mode, clientData]);

    const resetForm = () => {
        setFirstName('');
        setLastName('');
        setEmail('');
        setPhone('');
        setClientPin('');
        setClientDefaultPage('');
        setSelectedAdminId('');
        setClientId();
        setErrors({});
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        if (value.trim()) {
            setErrors(prev => ({ ...prev, [name]: '' })); // Clear specific error on input change
        }
    };

    const validateForm = () => {
        const newErrors = {};
        if (!firstName.trim()) newErrors.firstName = "First name is required.";
        if (!lastName.trim()) newErrors.lastName = "Last name is required.";
        if (!email.trim()) {
            newErrors.email = "Email is required.";
        } else if (!/\S+@\S+\.\S+/.test(email)) {  // Simple email format check
            newErrors.email = "Email is invalid.";
        }
        if (!clientPin.trim()) newErrors.clientPin = "Client Pin is required.";
        if (!clientDefaultPage.trim()) newErrors.clientDefaultPage = "Client Default Page is required.";
        if (!selectedAdminId) newErrors.selectedAdminId = "Admin selection is required.";
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = () => {
        if (!validateForm()) return;

        const clientDataToSubmit = {
            first_name: firstName,
            last_name: lastName,
            email: email,
            phone: phone,
            client_pin: clientPin,
            client_default_page: clientDefaultPage,
            client_main_id: selectedAdminId,
            client_id: client_id,
        };

        addUpdateClient(clientDataToSubmit, setClients);
        document.querySelector("#kt_modal_add_user .btn-close").click();
        resetForm();
    };

    return (
        <div className="modal fade" id="kt_modal_add_user" tabIndex="-1" aria-hidden="true">
            <div className="modal-dialog modal-dialog-centered mw-650px">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 className="modal-title">{mode === 'edit' ? 'Edit Client' : 'Add Client'}</h5>
                        <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close" onClick={resetForm}></button>
                    </div>
                    <div className="modal-body py-10 px-lg-17">
                        <div className="fv-row mb-7">
                            <label className="required fs-6 fw-semibold mb-2">First Name</label>
                            <input
                                type="text"
                                className={`form-control form-control-solid ${errors.firstName ? 'is-invalid' : ''}`}
                                value={firstName}
                                name="firstName"
                                onChange={(e) => { setFirstName(e.target.value); handleInputChange(e); }}
                            />
                            {errors.firstName && <span className="text-danger">{errors.firstName}</span>}
                        </div>
                        <div className="fv-row mb-7">
                            <label className="required fs-6 fw-semibold mb-2">Last Name</label>
                            <input
                                type="text"
                                className={`form-control form-control-solid ${errors.lastName ? 'is-invalid' : ''}`}
                                value={lastName}
                                name="lastName"
                                onChange={(e) => { setLastName(e.target.value); handleInputChange(e); }}
                            />
                            {errors.lastName && <span className="text-danger">{errors.lastName}</span>}
                        </div>
                        <div className="fv-row mb-7">
                            <label className="fs-6 fw-semibold mb-2">Email</label>
                            <input
                                type="email"
                                className={`form-control form-control-solid ${errors.email ? 'is-invalid' : ''}`}
                                value={email}
                                name="email"
                                onChange={(e) => { setEmail(e.target.value); handleInputChange(e); }}
                            />
                            {errors.email && <span className="text-danger">{errors.email}</span>}
                        </div>
                        <div className="fv-row mb-7">
                            <label className="fs-6 fw-semibold mb-2">Phone</label>
                            <input
                                type="text"
                                className="form-control form-control-solid"
                                value={phone}
                                onChange={(e) => setPhone(e.target.value)}
                            />
                        </div>
                        <div className="fv-row mb-7">
                            <label className="required fs-6 fw-semibold mb-2">Client Pin</label>
                            <input
                                type="text"
                                className={`form-control form-control-solid ${errors.clientPin ? 'is-invalid' : ''}`}
                                value={clientPin}
                                name="clientPin"
                                onChange={(e) => { setClientPin(e.target.value); handleInputChange(e); }}
                            />
                            {errors.clientPin && <span className="text-danger">{errors.clientPin}</span>}
                        </div>
                        <div className="fv-row mb-7">
                            <label className="required fs-6 fw-semibold mb-2">Client Default Page</label>
                            <input
                                type="text"
                                className={`form-control form-control-solid ${errors.clientDefaultPage ? 'is-invalid' : ''}`}
                                value={clientDefaultPage}
                                name="clientDefaultPage"
                                onChange={(e) => { setClientDefaultPage(e.target.value); handleInputChange(e); }}
                            />
                            {errors.clientDefaultPage && <span className="text-danger">{errors.clientDefaultPage}</span>}
                        </div>
                        <div className="fv-row mb-7">
                            <label className="required fs-6 fw-semibold mb-2">Assign Admin</label>
                            <select
                                className={`form-control form-control-solid ${errors.selectedAdminId ? 'is-invalid' : ''}`}
                                value={selectedAdminId}
                                name="selectedAdminId"
                                onChange={(e) => { setSelectedAdminId(e.target.value); handleInputChange(e); }}
                            >
                                <option value="">Select Admin</option>
                                {adminUsers?.map(admin => (
                                    <option key={admin.user_id} value={admin.user_id}>
                                        {admin.first_name} {admin.last_name}
                                    </option>
                                ))}
                            </select>
                            {errors.selectedAdminId && <span className="text-danger">{errors.selectedAdminId}</span>}
                        </div>
                    </div>
                    <div className="modal-footer">
                        <button type="button" className="btn btn-light" data-bs-dismiss="modal" onClick={resetForm}>{mode === 'edit' ? 'Discard Changes' : 'Close'}</button>
                        <button type="button" className="btn btn-primary" onClick={handleSubmit}>
                            {mode === 'edit' ? 'Save Changes' : 'Save'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AddClientModal;

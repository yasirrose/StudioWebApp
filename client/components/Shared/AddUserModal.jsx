import React, { useState } from 'react';

export default function AddUserModal({ show, onClose, onSubmit }) {
  const [userData, setUserData] = useState({
    name: '',
    email: '',
    role: 'User', // Default role
    active: true,
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(userData);
    onClose(); 
  };

  return (
    <div className="modal fade" id="kt_modal_add_user" tabIndex="-1" aria-hidden="true">
      <div className="modal-dialog modal-dialog-centered mw-650px">
        <div className="modal-content">
          <form onSubmit={handleSubmit}>
            <div className="modal-header">
              <h2 className="fw-bold">Add User</h2>
              <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div className="modal-body">
              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold required">User Name</label>
                <input
                  type="text"
                  className="form-control form-control-solid"
                  value={userData.name}
                  onChange={(e) => setUserData({ ...userData, name: e.target.value })}
                  required
                />
              </div>

              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold required">Email</label>
                <input
                  type="email"
                  className="form-control form-control-solid"
                  value={userData.email}
                  onChange={(e) => setUserData({ ...userData, email: e.target.value })}
                  required
                />
              </div>

              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold required">Phone</label>
                <input
                  type="text"
                  className="form-control form-control-solid"
                  value={userData.phone}
                  onChange={(e) => setUserData({ ...userData, phone: e.target.value })}
                  
                />
              </div>

              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold">Role</label>
                <select
                  className="form-control form-control-solid"
                  value={userData.role}
                  onChange={(e) => setUserData({ ...userData, role: e.target.value })}
                >
                  <option value="Admin">Admin</option>
                  <option value="Editor">Editor</option>
                  <option value="User">User</option>
                </select>
              </div>

              <div className="form-group mb-9">
                <label className="form-check form-check-custom form-check-solid">
                  <input
                    type="checkbox"
                    className="form-check-input"
                    checked={userData.active}
                    onChange={() => setUserData({ ...userData, active: !userData.active })}
                  />
                  <span className="form-check-label fw-semibold">Active</span>
                </label>
              </div>
            </div>
            <div className="modal-footer">
                <button type="button" className="btn btn-light" data-bs-dismiss="modal">Close</button>
              <button type="submit" className="btn btn-primary">Submit</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

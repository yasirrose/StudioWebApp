import React, { useState } from 'react';

export default function AddEventModal({ show, onClose, onSubmit }) {
  const [eventData, setEventData] = useState({
    name: '',
    description: '',
    location: '',
    startDate: '',
    startTime: '',
    endDate: '',
    endTime: '',
    allDay: false,
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(eventData);
    onClose(); // Close modal after submission
  };

  return (
    <>
        <div
        className={`modal fade ${show ? 'show' : ''}`}
        tabIndex="-1"
        role="dialog"
        style={{ display: show ? 'block' : 'none' }}
        aria-hidden="true"
      >
      <div className="modal-dialog modal-dialog-centered mw-650px" role="document">
        <div className="modal-content">
          <form onSubmit={handleSubmit}>
            <div className="modal-header">
              <h2 className="fw-bold">Add Event</h2>
              <button type="button" className="btn-close" onClick={onClose} data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div className="modal-body">
              {/* Event Name */}
              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold required">Event Name</label>
                <input
                  type="text"
                  className="form-control form-control-solid"
                  value={eventData.name}
                  onChange={(e) => setEventData({ ...eventData, name: e.target.value })}
                  required
                />
              </div>
              {/* Event Description */}
              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold">Event Description</label>
                <input
                  type="text"
                  className="form-control form-control-solid"
                  value={eventData.description}
                  onChange={(e) => setEventData({ ...eventData, description: e.target.value })}
                />
              </div>
              {/* Event Location */}
              <div className="form-group mb-9">
                <label className="fs-6 fw-semibold">Event Location</label>
                <input
                  type="text"
                  className="form-control form-control-solid"
                  value={eventData.location}
                  onChange={(e) => setEventData({ ...eventData, location: e.target.value })}
                />
              </div>
              {/* Event Dates and Times */}
              <div className="row row-cols-lg-2 g-10">
                <div className="col">
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold required">Event Start Date</label>
                    <input
                      type="date"
                      className="form-control form-control-solid"
                      value={eventData.startDate}
                      onChange={(e) => setEventData({ ...eventData, startDate: e.target.value })}
                      required
                    />
                  </div>
                </div>
                <div className="col">
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold">Event Start Time</label>
                    <input
                      type="time"
                      className="form-control form-control-solid"
                      value={eventData.startTime}
                      onChange={(e) => setEventData({ ...eventData, startTime: e.target.value })}
                    />
                  </div>
                </div>
              </div>
              <div className="row row-cols-lg-2 g-10">
                <div className="col">
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold required">Event End Date</label>
                    <input
                      type="date"
                      className="form-control form-control-solid"
                      value={eventData.endDate}
                      onChange={(e) => setEventData({ ...eventData, endDate: e.target.value })}
                      required
                    />
                  </div>
                </div>
                <div className="col">
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold">Event End Time</label>
                    <input
                      type="time"
                      className="form-control form-control-solid"
                      value={eventData.endTime}
                      onChange={(e) => setEventData({ ...eventData, endTime: e.target.value })}
                    />
                  </div>
                </div>
              </div>
              {/* All Day Checkbox */}
              <div className="form-group mb-9">
                <label className="form-check form-check-custom form-check-solid">
                  <input
                    type="checkbox"
                    className="form-check-input"
                    checked={eventData.allDay}
                    onChange={() => setEventData({ ...eventData, allDay: !eventData.allDay })}
                  />
                  <span className="form-check-label fw-semibold">All Day</span>
                </label>
              </div>
            </div>
            <div className="modal-footer">
              <button type="reset" className="btn btn-light me-3" onClick={onClose}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary">Submit</button>
            </div>
          </form>
        </div>
      </div>
    </div>
    {show && <div className="modal-backdrop fade show"></div>}
    </>
  );
}

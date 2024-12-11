import React, { useState } from 'react';
import { AiOutlineClose } from 'react-icons/ai';
import DatePicker from "react-multi-date-picker";
import TimePicker from "react-multi-date-picker/plugins/time_picker";

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
  const [startDate, setStartDate] = useState(null); // State for Start Date
  const [endDate, setEndDate] = useState(null); // State for End Date
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
              <button
              type="button"
              className="btn close-btn"
              onClick={onClose}
            >
              <AiOutlineClose size={24} />
            </button>
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

              {/* Event Dates and Times */}
              <div className="row row-cols-lg-2 g-10">
                <div className="col">
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold required">Event Start Date</label>
                    <DatePicker
                      value={startDate}
                      placeholder="YYYY-MM-DD"
                      onChange={setStartDate}
                      format="YYYY-MM-DD"
                    />
                  </div>
                </div>
                <div className="col">
                  {
                  !eventData.allDay &&
                    <div className="form-group mb-9">
                      <label className="fs-6 fw-semibold">Event Start Time</label>
                      <DatePicker
                        disableDayPicker
                        format="hh:mm A"
                        placeholder='HH:MM'
                        plugins={[
                          <TimePicker hideSeconds />
                        ]} 
                      />
                    </div>
                  }
                </div>
              </div>
              <div className="row row-cols-lg-2 g-10">
                <div className="col">
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold required">Event End Date</label>
                    <DatePicker
                      value={endDate}
                      placeholder="YYYY-MM-DD"
                      onChange={setEndDate}
                      format="YYYY-MM-DD"
                    />
                  </div>
                </div>
                <div className="col">
                {
                  !eventData.allDay &&
                  <div className="form-group mb-9">
                    <label className="fs-6 fw-semibold">Event End Time</label>
                    <DatePicker
                      disableDayPicker
                      format="hh:mm A"
                      placeholder='HH:MM'
                      plugins={[
                        <TimePicker hideSeconds />
                      ]} 
                    />
                  </div>
                }
                </div>
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

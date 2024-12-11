import React, { useState, useEffect, useCallback } from 'react';
import { IoCheckmarkCircleOutline, IoPersonOutline, IoLocationOutline, IoMailOutline } from 'react-icons/io5';
import { useRouter } from 'next/router';

const UserProfile = ({profileData, loading, error, setIsEditProfile}) => {
     
    const router = useRouter();

    // if (loading) {
    //     return <div>Loading...</div>;
    // } else {
    //     // console.log("--in-- profileData = ", profileData);
    //     // debugger;
    // }

    // if (error) {
    //     return <div>Error: {error}</div>;
    // }

    // Helper function to format the display of user profile fields
    const formatField = (fieldValue) => {
        return fieldValue && fieldValue.trim() !== ""
            ? fieldValue
            : <i style={{ color: '#d3d3d3' }}>NA</i>;
    };
    
    console.log("editprofile----profileData   = ", profileData);


    const user = profileData?.length > 0 ? profileData[0] : null;
    const fullName = user?.first_name.concat(' ', user?.last_name);

    return (
        <div className="app-main flex-column flex-row-fluid " id="kt_app_main">
            <div className="d-flex flex-column flex-column-fluid">
                <div id="kt_app_content" className="app-content  flex-column-fluid ">
                    <div id="kt_app_content_container" className="app-container  container-fluid ">
                    <div className="card mb-5 mb-xl-10">
                        <div className="card-body pt-9 pb-0">
                        <div className="d-flex flex-wrap flex-sm-nowrap">
                            <div className="me-7 mb-4">
                            <div className="symbol symbol-100px symbol-lg-160px symbol-fixed position-relative">
                                <img src="./images/user-image.jpg" alt="User Image" />
                                <div className="position-absolute translate-middle bottom-0 start-100 mb-6 bg-success rounded-circle border border-4 border-body h-20px w-20px"></div>
                            </div>
                            </div>
                            <div className="flex-grow-1">
                            <div className="d-flex justify-content-between align-items-start flex-wrap mb-2">
                                <div className="d-flex flex-column">
                                <div className="d-flex align-items-center mb-2">
                                    <a href="#" className="text-gray-900 text-hover-primary fs-2 fw-bold me-1">{fullName} </a>
                                    <a href="#" className="check-icon">
                                        <IoCheckmarkCircleOutline className="fs-1 text-primary" />
                                    </a>
                                </div>
                                <div className="d-flex flex-wrap fw-semibold fs-6 mb-4 pe-2">
                                    <a href="#" className="d-flex align-items-center text-gray-500 text-hover-primary me-5 mb-2">
                                        <i className="ki-outline ki-profile-circle fs-4 me-1"></i> <IoPersonOutline className="fs-4 me-1" /> Developer
                                    </a>
                                    <a href="#" className="d-flex align-items-center text-gray-500 text-hover-primary me-5 mb-2">
                                        <IoLocationOutline className="fs-4 me-1" /> {user?.address}
                                    </a>
                                    <a href="#" className="d-flex align-items-center text-gray-500 text-hover-primary mb-2">
                                        <IoMailOutline className="fs-4 me-1" /> {user?.email}
                                    </a>
                                </div>
                                </div>
                                <div className="d-flex my-4">
                                <a href="#" className="btn btn-sm btn-light me-2">
                                    Follow
                                </a>
                                <a href="#" className="btn btn-sm btn-primary me-3">Hire Me</a>
                                </div>
                            </div>
                            </div>
                        </div>
                        </div>
                    </div>

                    {/* Profile Details */}
                    <div className="card mb-5 mb-xl-10">
                        <div className="card-header cursor-pointer">
                        <div className="card-title m-0">
                            <h3 className="fw-bold m-0">Profile Details</h3>
                        </div>
                        <button className="btn btn-sm btn-primary align-self-center" onClick={() => setIsEditProfile(true)}>
                            Edit Profile
                        </button>
                        </div>
                        <div className="card-body p-9">
                        <div className="row mb-7">
                            <label className="col-lg-4 fw-semibold text-muted">Full Name</label>
                            <div className="col-lg-8">
                            <span className="fw-bold fs-6 text-gray-800">{fullName}</span>
                            </div>
                        </div>
                        {/* <div className="row mb-7">
                            <label className="col-lg-4 fw-semibold text-muted">Company</label>
                            <div className="col-lg-8 fv-row">
                            <span className="fw-semibold text-gray-800 fs-6">{formatField(user.company)}</span>
                            </div>
                        </div> */}
                        <div className="row mb-7">
                            <label className="col-lg-4 fw-semibold text-muted">Contact Phone</label>
                            <div className="col-lg-8 d-flex align-items-center">
                            <span className="fw-bold fs-6 text-gray-800 me-2">{formatField(user?.phone)}</span>
                            {/* <span className="badge badge-success">Verified</span> */}
                            </div>
                        </div>
                        {/* <div className="row mb-7">
                            <label className="col-lg-4 fw-semibold text-muted">Company Site</label>
                            <div className="col-lg-8">
                            <a href="#" className="fw-semibold fs-6 text-gray-800 text-hover-primary">{formatField(user.company_site)}</a>
                            </div>
                        </div> */}
                        {/* <div className="row mb-7">
                            <label className="col-lg-4 fw-semibold text-muted">Country</label>
                            <div className="col-lg-8">
                            <a href="#" className="fw-semibold fs-6 text-gray-800 text-hover-primary">{formatField(user.Country)}</a>
                            </div>
                        </div> */}
                        
                        <div className="row mb-6">
                            <label className="col-lg-4 col-form-label fw-semibold fs-6">Time Zone</label>
                            <div className="col-lg-8">
                            <select
                                name="timezone"
                                className="form-select form-select-solid form-select-lg fw-semibold"
                                // value={user.timezone}
                                // onChange={handleInputChange}
                            >
                                <option value="">Select a timezone..</option>
                                <option value="International Date Line West">(GMT-11:00) International Date Line West</option>
                                <option value="Midway Island">(GMT-11:00) Midway Island</option>
                            </select>
                            </div>
                        </div>
                        </div>
                    </div>

                    </div>
                </div>
            </div>
        </div>
    );
};

export default UserProfile;

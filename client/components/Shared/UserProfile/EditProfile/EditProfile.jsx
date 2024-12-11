"use client";
import { useState, useEffect, useRef } from "react";
import styles from "./editProfile.module.scss";
import { FaPencilAlt, FaTimes } from "react-icons/fa"; 
import { useUpdateUserProfile } from '/hooks/userProfile';
import { useAddUser } from '/hooks/users';
import { useRouter } from 'next/router';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { useTheme } from '/context/ThemeContext';

const EditProfile = ({ profileData, setProfileData, setIsEditProfile }) => {
    const { updateUserProfile, loading, error } = useUpdateUserProfile();
    const { addUser } = useAddUser();
    const router = useRouter();
    const { query } = router;
    console.log("-------LOADING", loading);
    
    

    // console.log("editprofiel.jsx----profileData =", profileData);
    
    const user = profileData.length > 0 ? profileData[0] : null;
    const [formData, setFormData] = useState({
        first_name: "",
        last_name: "",
        company: "",
        phone: "",
        email: "",
        company_site: "",
        address: "",
        country: "",
        timezone: "",
        avatar: "",
    });

    const [formErrors, setFormErrors] = useState({});
    const [avatarPreview, setAvatarPreview] = useState(null);
    const fileInputRef = useRef(null);

    const [emailEditVisible, setEmailEditVisible] = useState(false);
    const [passwordEditVisible, setPasswordEditVisible] = useState(false);
    const { theme, isDarkMode } = useTheme();

    useEffect(() => {
        if (user) {
            setFormData({
                user_id: user.user_id || "",
                first_name: user.first_name || "",
                last_name: user.last_name || "",
                company: user.company || "",
                phone: user.phone || "",
                email: user.email || "",
                company_site: user.company_site || "",
                address: user.address || "",
                country: user.country || "",
                timezone: user.timezone || "",
                avatar: user.avatar || "",
            });
        }
    }, [user]);

    // Function to validate form
    const validateForm = () => {
        const errors = {};
        if (!formData.first_name.trim()) errors.first_name = "First name is required.";
        if (!formData.email.trim()) {
            errors.email = "Email is required.";
        } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
            errors.email = "Email format is invalid.";
        }
        setFormErrors(errors);
        return Object.keys(errors).length === 0;
    };


    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData({
            ...formData,
            [name]: value,
        });

        if (value.trim()) {
            setFormErrors(prev => ({ ...prev, [name]: '' })); // Clear specific error on input change
        }
    };

    const handleAvatarChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            const imageUrl = URL.createObjectURL(file);
            setAvatarPreview(imageUrl);
            setFormData({ ...formData, avatar: file });
        }
    };

    const handleEditClick = () => {
        fileInputRef.current.click();
    };

    const handleDeleteClick = () => {
        setAvatarPreview(null);
        fileInputRef.current.value = null;
        setFormData({ ...formData, avatar: '' });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        // Validate form before submission
        const isValid = validateForm();
        if (!isValid) return;

        console.log("------ formData =", formData);
        if (query?.mode === 'add') {
            await addUser(formData);
            router.push('/users');                
        } else {
            if (query?.mode === 'edit') {
                router.push('/users');                
            }
            const updatedProfileData = await updateUserProfile(formData);
            setProfileData(updatedProfileData);
        }
        setIsEditProfile(false);
    };

    const handleCancel = () => {
        if (query?.mode === 'add' || query?.mode === 'edit') {
            router.push('/users'); // Redirect on cancel in add mode
        } else {
            setIsEditProfile(false); // Close edit form in edit mode
        }
    };

    const [collapsed, setCollapsed] = useState(false);

    return (
        <main className="app-main flex-column flex-row-fluid" id="kt_app_main">
            <div className="d-flex flex-column flex-column-fluid">
                <ToastContainer />
                <div id="kt_app_content" className="app-content flex-column-fluid">
                    <div id="kt_app_content_container" className="app-container container-fluid">
                        <div className="card mb-5 mt-5 mb-xl-10">
                            <div className="card-header border-0">
                                <div className="card-title m-0">
                                    <h3 className="fw-bold m-0">My Details</h3>
                                </div>
                            </div>
                            <form onSubmit={handleSubmit} className="form">
                                <div className="card-body border-top p-9">
                                    <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Avatar</label>
                                        <div className="col-lg-8">
                                            <div className={`${styles.userImage} image-input image-input-outline`}>
                                                <div className="image-input-wrapper w-125px h-125px"
                                                    style={{
                                                        backgroundImage: avatarPreview ? `url(${avatarPreview})` : "url('/images/placeholder-image.png')",
                                                        backgroundSize: "cover",
                                                        backgroundPosition: "center",
                                                    }}
                                                ></div>
                                                <button type="button" className={styles.editBtn} onClick={handleEditClick}>
                                                    <FaPencilAlt />
                                                </button>
                                                {avatarPreview && (
                                                    <button type="button" className={styles.deleteBtn} onClick={handleDeleteClick}>
                                                        <FaTimes />
                                                    </button>
                                                )}
                                                <input type="file" name="avatar" accept=".png, .jpg, .jpeg" ref={fileInputRef} style={{ display: "none" }} onChange={handleAvatarChange} />
                                            </div>
                                            <div className="form-text">Allowed file types: png, jpg, jpeg.</div>
                                        </div>
                                    </div>
                                    <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Full Name</label>
                                        <div className="col-lg-8">
                                            <div className="row">
                                                <div className="col-lg-6">
                                                    <input type="text" name="first_name" className={`form-control form-control-lg form-control-solid ${formErrors.first_name ? 'is-invalid' : ''}`}
                                                        placeholder="First name" value={formData.first_name} onChange={handleInputChange} />
                                                        {formErrors.first_name && <div className="text-danger">{formErrors.first_name}</div>}
                                                </div>
                                                <div className="col-lg-6">
                                                    <input type="text" name="last_name" className="form-control form-control-lg form-control-solid"
                                                        placeholder="Last name" value={formData.last_name} onChange={handleInputChange} />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Email</label>
                                        <div className="col-lg-8">
                                            <input type="text" name="email" className={`form-control form-control-lg form-control-solid ${formErrors.email ? 'is-invalid' : ''}`}
                                                placeholder="Email" value={formData.email} onChange={handleInputChange} />
                                                {formErrors.email && <div className="text-danger">{formErrors.email}</div>}
                                        </div>
                                    </div>
                                    <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Contact Phone</label>
                                        <div className="col-lg-8">
                                            <input type="tel" name="phone" className="form-control form-control-lg form-control-solid"
                                                placeholder="Phone number" value={formData.phone} onChange={handleInputChange} />
                                        </div>
                                    </div>
                                    {/* <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Address</label>
                                        <div className="col-lg-8">
                                            <input type="text" name="address" className="form-control form-control-lg form-control-solid"
                                                placeholder="Address" value={formData.address} onChange={handleInputChange} />
                                        </div>
                                    </div> */}
                                    <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Time Zone</label>
                                        <div className="col-lg-8">
                                            <select name="timezone" className="form-select form-select-solid form-select-lg fw-semibold" value={formData.timezone} onChange={handleInputChange}>
                                                <option value="">Select Time Zone</option>
                                                <option value="UTC">UTC</option>
                                                <option value="GMT">GMT</option>
                                                {/* Add more time zone options here */}
                                            </select>
                                        </div>
                                    </div>
                                    {/* <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Company</label>
                                        <div className="col-lg-8">
                                            <input type="text" name="company" className="form-control form-control-lg form-control-solid"
                                                placeholder="Company name" value={formData.company} onChange={handleInputChange} />
                                        </div>
                                    </div> */}
                                    {/* <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Website</label>
                                        <div className="col-lg-8">
                                            <input type="url" name="company_site" className="form-control form-control-lg form-control-solid"
                                                placeholder="Website URL" value={formData.company_site} onChange={handleInputChange} />
                                        </div>
                                    </div> */}
                                    {/* <div className="row mb-6">
                                        <label className="col-lg-4 col-form-label fw-semibold fs-6">Country</label>
                                        <div className="col-lg-8">
                                            <input type="text" name="country" className="form-control form-control-lg form-control-solid"
                                                placeholder="Country" value={formData.country} onChange={handleInputChange} />
                                        </div>
                                    </div> */}
                                </div>
                                <div className="card-footer d-flex justify-content-end">
                                    <button type="button" className="btn btn-secondary ms-3"  onClick={handleCancel}>
                                        {query?.mode === 'add' ? "Cancel" : "Discard Changes"}
                                    </button>
                                    <button type="submit" className="btn btn-primary" disabled={loading}>
                                    {loading ? "Saving..." : query?.mode === 'add' ? "Save" : "Save Changes"}
                                    </button>
                                </div>
                            </form>
                        </div>
                        <div className="card mb-5 mb-xl-10 signin-method">
                            <div
                                className="card-header cursor-pointer"
                                role="button"
                                onClick={() => setEmailEditVisible(!emailEditVisible)}
                                >
                                <div className="card-title m-0">
                                    <h3 className="fw-bold m-0">Security Settings</h3>
                                </div>
                            </div>

                            <div className="collapse show">
                            <div className="card-body p-9">
                                <div className="d-flex flex-wrap align-items-center">
                                    <div id="kt_signin_email" className={emailEditVisible ? "d-none" : "method-content"}>
                                        <p className="fs-6 fw-bold mb-1">Email Address</p>
                                        <span className="fw-semibold text-gray-600">{formData.email}</span>
                                    </div>

                                    <div className={emailEditVisible ? "edit-change-email" : "d-none"}>
                                        <form>
                                        <div className="row mb-6">
                                            <div className="col-lg-6 mb-4">
                                            <label className="form-label fs-6 fw-bold mb-3">Enter New Email Address</label>
                                            <input
                                                type="email"
                                                className="form-control form-control-lg form-control-solid"
                                                placeholder="Email Address"
                                                defaultValue={formData.email}
                                            />
                                            </div>
                                            <div className="col-lg-6">
                                            <label className="form-label fs-6 fw-bold mb-3">Confirm Password</label>
                                            <input
                                                type="password"
                                                className="form-control form-control-lg form-control-solid"
                                            />
                                            </div>
                                        </div>
                                        <div className="d-flex">
                                            <button type="button" className="btn btn-primary me-2 px-6">Update Email</button>
                                            <button type="button" className="btn btn-color-gray-500 cancel-btn btn-active-light-primary px-6" onClick={() => setEmailEditVisible(false)}>Cancel</button>
                                        </div>
                                        </form>
                                    </div>

                                    <div className={emailEditVisible ? "d-none" : "ms-auto"}>
                                        <button className="btn btn-light btn-active-light-primary" onClick={() => setEmailEditVisible(!emailEditVisible)}>Change Email</button>
                                    </div>
                                </div>

                                <div className="separator separator-dashed my-6"></div>

                                <div className="d-flex flex-wrap align-items-center">
                                <div id="kt_signin_password" className={passwordEditVisible ? "d-none" : "method-content"}>
                                    <p className="fs-6 fw-bold mb-1">Password</p>
                                    <span className="fw-semibold text-gray-600">************</span>
                                </div>

                                <div className={passwordEditVisible ? "reset-password" : "d-none"}>
                                    <form>
                                    <div className="row mb-1">
                                        <div className="col-lg-4">
                                        <label className="form-label fs-6 fw-bold mb-3">Current Password</label>
                                        <input type="password" className="form-control form-control-lg form-control-solid" />
                                        </div>
                                        <div className="col-lg-4">
                                        <label className="form-label fs-6 fw-bold mb-3">New Password</label>
                                        <input type="password" className="form-control form-control-lg form-control-solid" />
                                        </div>
                                        <div className="col-lg-4">
                                        <label className="form-label fs-6 fw-bold mb-3">Confirm New Password</label>
                                        <input type="password" className="form-control form-control-lg form-control-solid" />
                                        </div>
                                    </div>
                                    <div className="form-text mb-5">Password must be at least 8 characters and contain symbols</div>
                                    <div className="d-flex">
                                        <button type="button" className="btn btn-primary me-2 px-6">Update Password</button>
                                        <button type="button" className="btn btn-color-gray-500 cancel-btn btn-active-light-primary px-6" onClick={() => setPasswordEditVisible(false)}>Cancel</button>
                                    </div>
                                    </form>
                                </div>

                                <div className={passwordEditVisible ? "d-none" : "ms-auto"}>
                                    <button className="btn btn-light btn-active-light-primary" onClick={() => setPasswordEditVisible(!passwordEditVisible)}>Reset Password</button>
                                </div>
                                </div>
                            </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
};

export default EditProfile;

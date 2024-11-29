"use client";
import { useState, useRef } from "react";
import Header from "../../components/common/Header";
import Footer from "../../components/common/Footer";
import Sidebar from "../../components/common/Sidebar";
import styles from "./editProfile.module.scss";
import { FaPencilAlt, FaTimes } from "react-icons/fa"; // Use FaTimes for the cross icon

const Profile = () => {
  const [formData, setFormData] = useState({
    fname: "Max",
    lname: "Smith",
    phone: "044 3276 454 935",
    country: "",
    timezone: "",
  });

  const [avatarPreview, setAvatarPreview] = useState(null);
  const fileInputRef = useRef(null);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const handleAvatarChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      const imageUrl = URL.createObjectURL(file);
      setAvatarPreview(imageUrl);
    }
  };

  const handleEditClick = () => {
    fileInputRef.current.click();
  };

  const handleDeleteClick = () => {
    setAvatarPreview(null);
    fileInputRef.current.value = null;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
  };

  return (
      <div className={`main-screen ${ theme === "system" ? "systemMode" : isDarkMode ? "darkMode" : "lightMode" }`}>
      <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
      <div className={`main-content ${collapsed ? 'collapsed' : ''}`}>
        <Header />
        <main className="app-main flex-column flex-row-fluid" id="kt_app_main">
          <div className={`${styles.editProfile} ${ theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode }`}>
            <div className="content-section d-flex flex-column flex-column-fluid">
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
                                  backgroundImage: avatarPreview ? `url(${avatarPreview})` : "none",
                                  backgroundSize: "cover",
                                  backgroundPosition: "center",
                                }}
                              ></div>

                              <button
                                type="button"
                                className={styles.editBtn}
                                onClick={handleEditClick}
                              >
                                <FaPencilAlt />
                              </button>

                              {avatarPreview && (
                                <button
                                  type="button"
                                  className={styles.deleteBtn}
                                  onClick={handleDeleteClick}
                                >
                                  <FaTimes /> {/* Cross icon */}
                                </button>
                              )}

                              <input
                                type="file"
                                name="avatar"
                                accept=".png, .jpg, .jpeg"
                                ref={fileInputRef}
                                style={{ display: "none" }}
                                onChange={handleAvatarChange}
                              />
                            </div>
                            <div className="form-text">Allowed file types: png, jpg, jpeg.</div>
                          </div>
                        </div>
                        <div className="row mb-6">
                          <label className="col-lg-4 col-form-label required fw-semibold fs-6">Full Name</label>
                          <div className="col-lg-8">
                            <div className="row">
                              <div className="col-lg-6">
                                <input
                                  type="text"
                                  name="fname"
                                  className="form-control form-control-lg form-control-solid mb-3"
                                  placeholder="First name"
                                  value={formData.fname}
                                  onChange={handleInputChange}
                                />
                              </div>
                              <div className="col-lg-6">
                                <input
                                  type="text"
                                  name="lname"
                                  className="form-control form-control-lg form-control-solid"
                                  placeholder="Last name"
                                  value={formData.lname}
                                  onChange={handleInputChange}
                                />
                              </div>
                            </div>
                          </div>
                        </div>

                        <div className="row mb-6">
                          <label className="col-lg-4 col-form-label fw-semibold fs-6">Contact Phone</label>
                          <div className="col-lg-8">
                            <input
                              type="tel"
                              name="phone"
                              className="form-control form-control-lg form-control-solid"
                              placeholder="Phone number"
                              value={formData.phone}
                              onChange={handleInputChange}
                            />
                          </div>
                        </div>

                        <div className="row mb-6">
                          <label className="col-lg-4 col-form-label fw-semibold fs-6">Country</label>
                          <div className="col-lg-8">
                            <select
                              name="country"
                              className="form-select form-select-solid form-select-lg fw-semibold"
                              value={formData.country}
                              onChange={handleInputChange}
                            >
                              <option value="">Select a country...</option>
                              <option value="AF">Afghanistan</option>
                              <option value="AX">Aland Islands</option>
                            </select>
                          </div>
                        </div>

                        <div className="row mb-6">
                          <label className="col-lg-4 col-form-label fw-semibold fs-6">Time Zone</label>
                          <div className="col-lg-8">
                            <select
                              name="timezone"
                              className="form-select form-select-solid form-select-lg fw-semibold"
                              value={formData.timezone}
                              onChange={handleInputChange}
                            >
                              <option value="">Select a timezone..</option>
                              <option value="International Date Line West">(GMT-11:00) International Date Line West</option>
                              <option value="Midway Island">(GMT-11:00) Midway Island</option>
                            </select>
                          </div>
                        </div>
                      </div>

                      <div className="card-footer d-flex justify-content-end py-6 px-9">
                        <button type="reset" className="btn btn-light btn-active-light-primary me-2">
                          Discard
                        </button>
                        <button type="submit" className="btn btn-primary">
                          111 -Save Changes
                        </button>
                      </div>
                    </form>
                  </div>
                  
                </div>
              </div>
            </div>
          </div>
        </main>
        <Footer />
      </div>
    </div>
  );
};

export default Profile;

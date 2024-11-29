"use client";
import React, { useState } from "react";
import { signIn } from 'next-auth/react';
import { ToastContainer, toast } from 'react-toastify';
import { useRouter } from 'next/router';
import 'react-toastify/dist/ReactToastify.css';
import { useAuth } from "../../context/authContext"; // Get the authenticate function

const ClientSignin = ({ onBackToSignin }) => {
    const [pincode, setPinCode] = useState("");
    const [error, setError] = useState("");
    const { authenticateUser } = useAuth(); // Get the authenticate function
    const router = useRouter();

    // Validation for 6-digit numeric PIN
    const validatePinCode = () => {
        if (!/^\d{6}$/.test(pincode)) {
            setError("Please enter a valid 6-digit PIN code.");
            return false;
        }
        setError("");
        return true;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        // Validate the form before submitting
        if (!validatePinCode()) return;
        console.log("--------SING IN----", signIn);

        const result = await signIn('credentials', {
            redirect: false,
            pincode,
        });
        console.log("-client sign in-result = ", result);
        
        if (result.error) {
            toast.error("Invalid pin code");
        } else {
            authenticateUser();
            router.push('/scheduledtasks');
        }
    };

    return (
        <div className="signin-screen">
            <div className="d-flex flex-column flex-root">
                <div className="d-flex flex-column flex-column-fluid flex-lg-row">
                <div className="d-flex flex-center w-lg-50 pt-15 pt-lg-0 px-10">
                    <div className="d-flex flex-center flex-lg-start flex-column">
                    <img
                        alt="Logo"
                        src="/images/ipstudio.png"
                        style={{ maxWidth: "200px" }}
                    />
                    </div>
                </div>

                <div className="d-flex flex-column-fluid flex-lg-row-auto justify-content-center justify-content-lg-end p-12 p-lg-20">
                    <div className="bg-body d-flex flex-column align-items-stretch flex-center rounded-4 w-md-600px p-20">
                    <div className="d-flex flex-center flex-column flex-column-fluid px-lg-10 pb-15 pb-lg-20">
                        <form className="form w-100" onSubmit={handleSubmit}>
                            <div className="text-center mb-11">
                                <h1 className="text-gray-900 fw-bolder mb-3">
                                Enter Your PIN Code
                                </h1>
                            </div>

                            <div className="fv-row mb-8">
                                <input
                                type="text"
                                placeholder="6-Digit PIN Code"
                                value={pincode}
                                onChange={(e) => {
                                    const value = e.target.value;
                                    if (/^\d*$/.test(value) && value.length <= 6) {
                                    setPinCode(value);
                                    if (error) setError("");
                                    }
                                }}
                                className={`form-control bg-transparent ${
                                    error ? "is-invalid" : ""
                                }`}
                                />
                                {error && <span className="text-danger">{error}</span>}
                            </div>

                            <div className="d-grid mb-10">
                                <button type="submit" className="btn btn-primary">
                                <span className="indicator-label">Submit</span>
                                </button>
                            </div>

                            <div className="text-gray-500 text-center fw-semibold fs-6">
                                Not a Client?{" "}
                                <button onClick={onBackToSignin} className="link-primary btn p-0">
                                    Sign in as staff.
                                </button>
                            </div>
                        </form>
                    </div>
                    </div>
                </div>
                </div>
            </div>
        </div>
    );
};

export default ClientSignin;

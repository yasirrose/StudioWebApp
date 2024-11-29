"use client"; 
import React, { useState, useEffect } from "react";
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import {useSignUp} from '/hooks/auth';

const Signup = ({ onBackToSignin }) => {
    const { signUp, signUpUser, loading, error } = useSignUp();
    // const {signUp, signUpUser} = useSignUp();
    const [first_name, setFirstName] = useState("");
    const [last_name, setLastName] = useState("");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [errors, setErrors] = useState("");

    // Validation function
    const validateForm = () => {
        const newErrors = {};
        if (!first_name.trim()) newErrors.first_name = "First name is required.";
        if (!last_name.trim()) newErrors.last_name = "Last name is required.";
        if (!email) {
            newErrors.email = "Email is required.";
        } else if (!/\S+@\S+\.\S+/.test(email)) {
            newErrors.email = "Email format is invalid.";
        }

        const passwordRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*])[A-Za-z\d!@#$%^&*]{8,}$/;
        if (!password) {
            newErrors.password = "Password is required.";
        } else if (!passwordRegex.test(password)) {
            newErrors.password = "Password must be at least 8 characters long, contain at least one digit, one special character, and one uppercase letter.";
        }

        if (!confirmPassword) {
            newErrors.confirmPassword = "Please confirm your password.";
        } else if (password !== confirmPassword) {
            newErrors.confirmPassword = "Passwords do not match.";
        }
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validateForm()) return;
        await signUp(first_name, last_name, email, password);
    };

    useEffect(() => {
        if (signUpUser && signUpUser.STATUSCODE === 201) {
            onBackToSignin();
        }
    }, [signUpUser]);

    return (
        <div className="signin-screen">
            <div className="d-flex flex-column flex-root">
                <div className="d-flex flex-column flex-column-fluid flex-lg-row">
                <div className="d-flex flex-center w-lg-50 pt-15 pt-lg-0 px-10">
                    <div className="d-flex flex-center flex-lg-start flex-column">
                    <img alt="Logo" src="/images/ipstudio.png" style={{ maxWidth: "200px" }} />
                    </div>
                </div>

                <ToastContainer />

                <div className="d-flex flex-column-fluid flex-lg-row-auto justify-content-center justify-content-lg-end p-12 p-lg-20">
                    <div className="bg-body d-flex flex-column align-items-stretch flex-center rounded-4 w-md-600px p-20">
                    <div className="d-flex flex-center flex-column flex-column-fluid px-lg-10 pb-15 pb-lg-20">
                        <form className="form w-100" onSubmit={handleSubmit}>
                        <div className="text-center mb-11">
                            <h1 className="text-gray-900 fw-bolder mb-3">Sign Up</h1>
                        </div>

                        <div className="fv-row mb-8">
                            <input
                            type="text"
                            placeholder="First name"
                            className={`form-control bg-transparent ${errors.first_name ? 'is-invalid' : ''}`}
                            value={first_name}
                            onChange={(e) => { setFirstName(e.target.value); if (errors.first_name) setErrors(prev => ({ ...prev, first_name: '' })); }}
                            />
                            {errors.first_name && <span className="text-danger">{errors.first_name}</span>}
                        </div>

                        <div className="fv-row mb-8">
                            <input
                            type="text"
                            placeholder="Last name"
                            className={`form-control bg-transparent ${errors.last_name ? 'is-invalid' : ''}`}
                            value={last_name}
                            onChange={(e) => { setLastName(e.target.value); if (errors.last_name) setErrors(prev => ({ ...prev, last_name: '' })); }}
                            />
                            {errors.last_name && <span className="text-danger">{errors.last_name}</span>}
                        </div>

                        <div className="fv-row mb-8">
                            <input
                            type="text"
                            placeholder="Email"
                            className={`form-control bg-transparent ${errors.email ? 'is-invalid' : ''}`}
                            value={email}
                            onChange={(e) => { setEmail(e.target.value); if (errors.email) setErrors(prev => ({ ...prev, email: '' })); }}
                            />
                            {errors.email && <span className="text-danger">{errors.email}</span>}
                        </div>

                        <div className="fv-row mb-8">
                            <input
                            type="password"
                            placeholder="Password"
                            className={`form-control bg-transparent ${errors.password ? 'is-invalid' : ''}`}
                            value={password}
                            onChange={(e) => { setPassword(e.target.value); if (errors.password) setErrors(prev => ({ ...prev, password: '' })); }}
                            />
                            {errors.password && <span className="text-danger">{errors.password}</span>}
                        </div>

                        <div className="fv-row mb-8">
                            <input
                            type="password"
                            placeholder="Confirm Password"
                            className={`form-control bg-transparent ${errors.confirmPassword ? 'is-invalid' : ''}`}
                            value={confirmPassword}
                            onChange={(e) => { setConfirmPassword(e.target.value); if (errors.confirmPassword) setErrors(prev => ({ ...prev, confirmPassword: '' })); }}
                            /> 
                            {errors.confirmPassword && <span className="text-danger">{errors.confirmPassword}</span>}
                        </div>

                        {/* Loading Indicator */}
                        {loading && <p>Loading...</p>}

                        {error && <p style={{ color: 'red' }}>{error}</p>}

                        <div className="d-grid mb-10">
                            <button type="submit" className="btn btn-primary">
                            <span className="indicator-label">Sign Up</span>
                            </button>
                        </div>
                        <div className="text-gray-500 text-center fw-semibold fs-6">
                            Already a Member?{" "}
                            <button onClick={onBackToSignin} className="link-primary btn p-0">
                            Sign In
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

export default Signup;

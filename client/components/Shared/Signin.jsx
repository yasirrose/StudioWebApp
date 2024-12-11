"use client";
import React, { useState } from "react";
import { signIn } from 'next-auth/react';
import { ToastContainer, toast } from 'react-toastify';
import { useRouter } from 'next/router';
import 'react-toastify/dist/ReactToastify.css';
import { getSession, SessionProvider } from 'next-auth/react';

const Signin = ({ onSignIn, onForgotPassword, onSignUp, onClientSignin }) => {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [errors, setErrors] = useState({});
    const router = useRouter();

  // Validation function to update error state
    const validateForm = () => {
        const newErrors = {};
        if (!email.trim()) {
            newErrors.email = "Email is required.";
        } else if (!/\S+@\S+\.\S+/.test(email)) {
            newErrors.email = "Please enter a valid email address.";
        }

        if (!password.trim()) {
            newErrors.password = "Password is required.";
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        // Validate the form before submitting
        if (!validateForm()) return;

        const result = await signIn('credentials', {
            redirect: false,
            email,
            password,
        });
        console.log("--result = ", result);
        

        if (result.error) {
            toast.error("Invalid credentials!");
        } else {
            const session = await getSession();
            console.log("-response-session = ", session);
            if (session) {
                console.log("session = ", session);

                if(!localStorage.getItem('jwttoken')) {
                    localStorage.setItem("jwttoken", session.user.jwttoken);
                }
                if(!localStorage.getItem('id')) {
                    localStorage.setItem("id", session.user?.id);
                }
                if(!localStorage.getItem('clientId')) {
                    localStorage.setItem("clientId", session.user?.clientId);
                }
                if(!localStorage.getItem('role')) {
                    localStorage.setItem("role", session.user?.role);
                }
                if(!localStorage.getItem('roleId')) {
                    localStorage.setItem("roleId", session.user?.roleId);
                }

            }

            router.push('/dashboard');
        }
    };

    return (
        <div className="signin-screen">
        <div className="d-flex flex-column flex-root">
            <div className="d-flex flex-column flex-column-fluid flex-lg-row">
            <div className="d-flex flex-center w-lg-50 pt-15 pt-lg-0 px-10">
                <div className="d-flex flex-center flex-lg-start flex-column">
                <img alt="Logo" src="/images/ipstudio.png" style={{ maxWidth: "200px" }} />
                </div>
            </div>

            <ToastContainer/>

            <div className="d-flex flex-column-fluid flex-lg-row-auto justify-content-center justify-content-lg-end p-12 p-lg-20">
                <div className="bg-body d-flex flex-column align-items-stretch flex-center rounded-4 w-md-600px p-20">
                <div className="d-flex flex-center flex-column flex-column-fluid px-lg-10 pb-15 pb-lg-20">
                    <form className="form w-100" onSubmit={handleSubmit}>
                        <div className="text-center mb-11">
                            <h1 className="text-gray-900 fw-bolder mb-3">Sign In</h1>
                        </div>

                        <div className="fv-row mb-8">
                            <input
                            type="text"
                            placeholder="Email"
                            value={email}
                            onChange={(e) => { setEmail(e.target.value); if (errors.email) setErrors(prev => ({ ...prev, email: '' })); }}
                            className={`form-control bg-transparent ${errors.email ? 'is-invalid' : ''}`}
                            />
                            {errors.email && <span className="text-danger">{errors.email}</span>}
                        </div>

                        <div className="fv-row mb-3">
                            <input
                            type="password"
                            placeholder="Password"
                            value={password}
                            onChange={(e) => { setPassword(e.target.value); if (errors.password) setErrors(prev => ({ ...prev, password: '' })); }}
                            className={`form-control bg-transparent ${errors.password ? 'is-invalid' : ''}`}
                            />
                            {errors.password && <span className="text-danger">{errors.password}</span>}
                        </div>

                        {errors.form && <div className="text-danger text-center mb-3">{errors.form}</div>}

                        <div className="d-flex flex-stack flex-wrap gap-3 fs-base fw-semibold mb-8 justify-content-end">
                            <a
                            href="#"
                            className="link-primary"
                            onClick={(e) => {
                                e.preventDefault();
                                onForgotPassword();
                            }}
                            >
                            Forgot Password?
                            </a>
                        </div>

                        <div className="d-grid mb-10">
                            <button type="submit" className="btn btn-primary">
                            <span className="indicator-label">Sign In</span>
                            </button>
                        </div>

                        <div className="text-gray-500 text-center fw-semibold fs-6">
                            Not a Member yet?{" "}
                            <button
                            className="link-primary btn p-0"
                            onClick={(e) => {
                                e.preventDefault();
                                onSignUp(); 
                            }}
                            >
                            Sign up
                            </button>
                        </div>

                        <div className="text-gray-500 text-center fw-semibold fs-6">
                            Not staff?{" "}
                            <button
                            className="link-primary btn p-0"
                            onClick={(e) => {
                                e.preventDefault();
                                onClientSignin();
                            }}
                            >
                            Sign in as a client.
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

export default Signin;

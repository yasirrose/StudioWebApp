// components/Loader.js
import React from 'react';
import { useLoading } from '/context/LoadingContext';

const Loader = () => {
  const { loading } = useLoading();
  console.log('loading',loading);
  if (!loading) return null;

  return (
    <div className="main-loader">
      <div className="loader loader--rings"></div>
    </div>
  );
};

export default Loader;

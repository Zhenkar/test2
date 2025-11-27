import React from "react";
import { useNavigate } from "react-router-dom";



const Navbar = ({ user, onLogout }) => {

  const navigate = useNavigate();


  const handleLogout = () => {
    localStorage.removeItem("user");      // update state to hide button
    navigate("/login");  // redirect to login
  };

  return (
    <nav className="bg-blue-500 p-4 text-white flex justify-between items-center shadow-md">
      <h1 className="text-xl font-bold">Notes App</h1>
      {user && (
        <div className="flex items-center gap-4">
          <span>Hello, {user.username}</span>
          <button
            onClick={handleLogout}
            className="bg-white text-blue-500 px-3 py-1 rounded hover:bg-gray-100"
          >
            Logout
          </button>
        </div>
      )}
    </nav>
  );
};

export default Navbar;

import React, { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Notes from "./pages/Notes";
import Navbar from "./components/Navbar";

const App = () => {
  const [user, setUser] = useState(null);

  // ---- Load user from localStorage on first load ----
  useEffect(() => {
    const savedUser = localStorage.getItem("user");
    if (savedUser) {
      setUser(JSON.parse(savedUser));
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("user");
    setUser(null);
  };

  return (
    <BrowserRouter>
      <Navbar user={user} onLogout={handleLogout} />
      <Routes>

        {/* Root now shows Register */}
        <Route path="/" element={<Register />} />

        <Route
          path="/login"
          element={<Login setUser={setUser} />}
        />
        
        <Route path="/register" element={<Register />} />

        <Route
          path="/notes"
          element={
            <Notes user={user}/>
          }
        />
      </Routes>
    </BrowserRouter>
  );
};

export default App;

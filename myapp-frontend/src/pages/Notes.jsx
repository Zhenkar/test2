import React, { useEffect, useState } from "react";
import NoteCard from "../components/NoteCard";

const Notes = ({ user }) => {
  const [notes, setNotes] = useState([]);
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  // Show loading if user not loaded yet
  if (!user) {
    return <h1 className="p-4 text-center text-xl">Loading...</h1>;
  }

  // ---------- FETCH NOTES USING USER EMAIL ----------
  const fetchNotes = () => {
    const allNotes = JSON.parse(localStorage.getItem("notes")) || {};

    // If user has no notes, initialize empty list
    if (!allNotes[user.email]) {
      allNotes[user.email] = [];
      localStorage.setItem("notes", JSON.stringify(allNotes));
    }

    setNotes(allNotes[user.email]);
  };

  // ---------- SAVE NOTES BACK TO LOCAL STORAGE ----------
  const saveNotes = (updatedNotes) => {
    const allNotes = JSON.parse(localStorage.getItem("notes")) || {};
    allNotes[user.email] = updatedNotes;
    localStorage.setItem("notes", JSON.stringify(allNotes));
  };

  // ---------- ADD NOTE ----------
  const addNote = (e) => {
    e.preventDefault();

    const newNote = {
      id: Date.now(),
      title,
      content,
    };

    const updatedNotes = [...notes, newNote];

    setNotes(updatedNotes);
    saveNotes(updatedNotes);

    setTitle("");
    setContent("");
  };

  // ---------- DELETE NOTE ----------
  const deleteNote = (id) => {
    const updatedNotes = notes.filter((note) => note.id !== id);

    setNotes(updatedNotes);
    saveNotes(updatedNotes);
  };

  useEffect(() => {
    fetchNotes();
  }, []);

  return (
    <div className="bg-gray-100 min-h-screen">
      <div className="p-4 flex justify-center">
        <form onSubmit={addNote} className="w-full max-w-2xl flex gap-2">
          <input
            type="text"
            placeholder="Title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="flex-1 p-2 border rounded"
            required
          />

          <input
            type="text"
            placeholder="Content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="flex-2 p-2 border rounded"
            required
          />

          <button className="bg-blue-500 text-white px-4 rounded hover:bg-blue-600">
            Add
          </button>
        </form>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 p-4">
        {notes.map((note) => (
          <NoteCard key={note.id} note={note} onDelete={deleteNote} />
        ))}
      </div>
    </div>
  );
};

export default Notes;

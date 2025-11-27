import React, { useEffect, useState } from "react";
import { api } from "../services/api";
import NoteCard from "../components/NoteCard";

const Notes = ({ user }) => {
  const [notes, setNotes] = useState([]);
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  const fetchNotes = async () => {
    try {
      const res = await api.get(`/notes/${user.id}`);
      setNotes(res.data);
    } catch (err) {
      console.log(err);
    }
  };

  const addNote = async (e) => {
    e.preventDefault();
    try {
      await api.post("/notes", { user_id: user.id, title, content });
      setTitle("");
      setContent("");
      fetchNotes();
    } catch (err) {
      console.log(err);
    }
  };

  const deleteNote = async (id) => {
    await api.delete(`/notes/${id}`);
    fetchNotes();
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
          />
          <input
            type="text"
            placeholder="Content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="flex-2 p-2 border rounded"
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

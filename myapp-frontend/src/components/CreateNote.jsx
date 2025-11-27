import { useState } from "react";
import { api } from "../api";

export default function CreateNote({ refresh }) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  const addNote = async () => {
    if (!title.trim() && !content.trim()) return;

    await api.post("/", {
      title,
      content,
    });

    setTitle("");
    setContent("");
    refresh(); // reload notes
  };

  return (
    <div style={styles.box}>
      <input
        style={styles.input}
        placeholder="Title..."
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />

      <textarea
        style={styles.input}
        placeholder="Take a note..."
        value={content}
        onChange={(e) => setContent(e.target.value)}
      />

      <button style={styles.btn} onClick={addNote}>
        Add Note
      </button>
    </div>
  );
}

const styles = {
  box: {
    padding: 20,
    margin: "20px auto",
    width: 400,
    border: "1px solid #ddd",
    borderRadius: 10,
  },
  input: {
    width: "100%",
    padding: 10,
    marginBottom: 10,
    borderRadius: 5,
    border: "1px solid #ccc",
  },
  btn: {
    padding: "10px 15px",
    background: "#1976d2",
    color: "white",
    border: "none",
    borderRadius: 5,
    cursor: "pointer",
  },
};

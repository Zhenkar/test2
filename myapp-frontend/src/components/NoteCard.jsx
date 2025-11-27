export default function NoteCard({ note, onDelete }) {
      return (
        <div style={styles.card}>
          <h3>{note.title}</h3>
          <p>{note.content}</p>
    
          <button style={styles.btn} onClick={() => onDelete(note.id)}>
            Delete
          </button>
        </div>
      );
    }
    
    const styles = {
      card: {
        padding: 20,
        border: "1px solid #ddd",
        borderRadius: 10,
        width: 250,
        margin: 10,
      },
      btn: {
        marginTop: 10,
        padding: "5px 10px",
        background: "red",
        color: "white",
        border: "none",
        borderRadius: 5,
        cursor: "pointer",
      },
    };
    
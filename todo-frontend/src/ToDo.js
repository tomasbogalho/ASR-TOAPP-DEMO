import React, { useState, useEffect } from 'react';
import axios from 'axios';

function ToDo() {
    const [items, setItems] = useState([]);
    const [description, setDescription] = useState('');

    useEffect(() => {
        axios.get('http://10.0.3.4:6002/api/todo')
            .then(response => setItems(response.data))
            .catch(error => console.error('There was an error fetching the ToDo items!', error));
    }, []);

    const addItem = () => {
        axios.post('http://10.0.3.4:6002/api/todo', { description, isCompleted: false })
            .then(response => setItems([...items, response.data]))
            .catch(error => console.error('There was an error adding the ToDo item!', error));
    };

    return (
        <div>
            <h1>ToDo List</h1>
            <input value={description} onChange={e => setDescription(e.target.value)} />
            <button onClick={addItem}>Add</button>
            <ul>
                {items.map(item => (
                    <li key={item.id}>{item.description}</li>
                ))}
            </ul>
        </div>
    );
}

export default ToDo;
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL;

function ToDo() {
    const [items, setItems] = useState([]);
    const [description, setDescription] = useState('');
    const [backendIp, setBackendIp] = useState('');

    useEffect(() => {
        // Fetch ToDo items
        axios.get(`${API_BASE_URL}/api/todo`)
            .then(response => setItems(response.data))
            .catch(error => console.error('There was an error fetching the ToDo items!', error));

        // Fetch backend IP
        axios.get(`${API_BASE_URL}/api/backend-ip`)
            .then(response => setBackendIp(response.data))
            .catch(error => console.error('There was an error fetching the backend IP!', error));
    }, []);

    const addItem = () => {
        axios.post(`${API_BASE_URL}/api/todo`, { description, isCompleted: false })
            .then(response => setItems([...items, response.data]))
            .catch(error => console.error('There was an error adding the ToDo item!', error));
    };

    return (
        <div>
            <h1>ToDo List</h1>
            <p>Backend IP: {backendIp}</p>
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
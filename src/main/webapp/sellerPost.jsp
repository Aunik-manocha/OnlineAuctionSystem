<!DOCTYPE html>
<html>
<head>
<title>Post Item</title>
<style>
body { background:#f6f7fb; font-family:Arial; }
.card { background:#fff; width:600px; margin:auto; padding:20px; border-radius:12px; box-shadow:0 0 12px rgba(0,0,0,0.1);}
button { padding:10px; background:#111827; color:#fff; border:none; border-radius:8px; cursor:pointer; }
input, select { width:100%; padding:10px; margin:8px 0; }
</style>
</head>

<body>
<div class="card">
<h2>Create New Auction</h2>

<form method="post" action="insertItem.jsp">
    <label>Item Name</label>
    <input type="text" name="name" required>

    <label>Description</label>
    <input type="text" name="description" required>

    <label>Type</label>
    <select name="type">
        <option value="dress">Dress</option>
        <option value="shoes">Shoes</option>
        <option value="belt">Belt</option>
    </select>

    <label>Size</label><input name="size">
    <label>Color</label><input name="color">
    <label>Material</label><input name="material">
    <label>Width (for shoes/belt)</label><input name="width">
    <label>Length (for belt)</label><input name="length">

    <hr>

    <h3>Auction Details</h3>
    <label>Title</label><input name="title" required>
    <label>Initial Price</label><input name="initial_price" required>
    <label>Minimum Price</label><input name="minimum_price" required>
    <label>Bid Increment</label><input name="bid_increment" required>

    <h3>Show Your Name?</h3>
    <label><input type="radio" name="show_name" value="YES" checked> Yes</label><br>
    <label><input type="radio" name="show_name" value="NO"> No</label><br><br>

    <button type="submit">Create Auction</button>
</form>
</div>
</body>
</html>

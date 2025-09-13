import mongoose, { Schema, Document } from 'mongoose';

export interface IPurchase extends Document {
  userId: mongoose.Schema.Types.ObjectId;
  productId: mongoose.Schema.Types.ObjectId;
}

const PurchaseSchema: Schema = new Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
});

export default mongoose.model<IPurchase>('Purchase', PurchaseSchema);

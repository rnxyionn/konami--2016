import updatePlaceStore from "../stores/updatePlaceStore";
import {useEffect, useRef, useState} from "react";
import {getGameMedia, uploadGameThumbnail} from "../../../services/games";
import {multiGetAssetThumbnails} from "../../../services/thumbnails";
import ActionButton from "../../actionButton";
import useButtonStyles from "../../../styles/buttonStyles";

const Thumbnails = () => {
  const store = updatePlaceStore.useContainer();
  const fileRef = useRef(null);
  const buttonStyles = useButtonStyles();
  const [images, setImages] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const loadImages = async () => {
    const media = await getGameMedia({universeId: store.details.universeId});
    const imageMedia = media.filter(item => item.imageId && (item.assetType === 1 || item.assetType === 'Image'));
    if (!imageMedia.length) {
      setImages([]);
      return;
    }

    const thumbnails = await multiGetAssetThumbnails({assetIds: imageMedia.map(item => item.imageId)});
    setImages(imageMedia.map(item => ({
      imageId: item.imageId,
      imageUrl: thumbnails.find(image => image.targetId === item.imageId)?.imageUrl || null,
      approved: item.approved,
    })));
  };

  useEffect(() => {
    if (store.details?.universeId) {
      loadImages().catch(e => setFeedback(e.message));
    }
  }, [store.details?.universeId]);

  const upload = async () => {
    const file = fileRef.current?.files?.[0];
    if (uploading) return;
    if (!file) {
      setFeedback('Choose a PNG or JPEG image first.');
      return;
    }

    setUploading(true);
    setFeedback(null);
    try {
      await uploadGameThumbnail({universeId: store.details.universeId, file});
      setFeedback('Thumbnail uploaded and waiting for moderation.');
      fileRef.current.value = '';
      await loadImages();
    } catch (e) {
      setFeedback(e.response?.data?.errors?.[0]?.message || e.message);
    } finally {
      setUploading(false);
    }
  };

  return <div className='row mt-4'>
    <div className='col-12'>
      <h2 className='fw-bolder mb-4'>Game Thumbnails</h2>
      {feedback ? <p className='mb-2'>{feedback}</p> : null}
      <input ref={fileRef} type='file' accept='image/png,image/jpeg' />
      <div className='mt-3'>
        <ActionButton
          disabled={uploading}
          className={buttonStyles.normal + ' ' + buttonStyles.continueButton}
          label={uploading ? 'Uploading...' : 'Upload Thumbnail'}
          onClick={upload}
        />
      </div>
    </div>
    <div className='col-12 mt-4'>
      <div className='row'>
        {images.map(image => (
          <div className='col-6 col-lg-4 mb-3' key={image.imageId}>
            {image.imageUrl
              ? <img className='w-100' src={image.imageUrl} alt='Game thumbnail' />
              : <p className='mb-0'>Thumbnail #{image.imageId} is waiting for moderation.</p>}
          </div>
        ))}
        {!images.length ? <p className='mb-0'>No custom thumbnails uploaded.</p> : null}
      </div>
    </div>
  </div>
}

export default Thumbnails;
